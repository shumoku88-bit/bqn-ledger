package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/gdamore/tcell/v2"
	"github.com/rivo/tview"
)

// Section holds a report section's key and marker text.
type Section struct {
	Key    string
	Marker string
}

// State holds the application state.
type State struct {
	App            *tview.Application
	ReportView     *tview.TextView
	StatusBar      *tview.TextView
	Pages          *tview.Pages
	Sections       []Section
	CurrentSection int
	FullReport     string
	BaseDir        string
	RootDir        string
}

func main() {
	// Set transparent background to respect terminal colors
	tview.Styles.PrimitiveBackgroundColor = tcell.ColorDefault

	// Resolve root directory (where tools/ lives)
	rootDir, err := resolveRootDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	// Resolve base directory
	baseDir := os.Getenv("LEDGER_DATA_DIR")
	if baseDir == "" {
		baseDir = filepath.Join(rootDir, "data")
	}

	// Override from CLI arg
	if len(os.Args) > 1 {
		baseDir = os.Args[1]
	}

	s := &State{
		RootDir: rootDir,
		BaseDir: baseDir,
	}

	s.Sections = nil
	s.FullReport = "Loading..."

	// Build UI
	s.App = tview.NewApplication()
	s.ReportView = tview.NewTextView().
		SetDynamicColors(false).
		SetScrollable(true).
		SetWrap(false)
	s.StatusBar = tview.NewTextView().
		SetDynamicColors(true)
	s.Pages = tview.NewPages()

	// Main layout: report (fills space) + status bar (1 line)
	mainFlex := tview.NewFlex().
		SetDirection(tview.FlexRow).
		AddItem(s.ReportView, 0, 1, true).
		AddItem(s.StatusBar, 1, 1, false)

	s.Pages.AddPage("main", mainFlex, true, true)

	// Key bindings
	s.App.SetInputCapture(s.handleInput)

	s.ReportView.SetText("Loading report from BQN engine...")
	s.StatusBar.SetText(" Loading...")

	// Background load
	go func() {
		sections := loadSections(s.RootDir, s.BaseDir)
		report := loadReport(s.RootDir, s.BaseDir)
		s.App.QueueUpdateDraw(func() {
			if len(sections) == 0 {
				s.ReportView.SetText("error: no sections found")
				return
			}
			s.Sections = sections
			s.FullReport = report
			s.CurrentSection = 0
			s.refresh()
		})
	}()

	if err := s.App.SetRoot(s.Pages, true).EnableMouse(true).Run(); err != nil {
		panic(err)
	}
}

func resolveRootDir() (string, error) {
	exe, err := os.Executable()
	if err != nil {
		return "", err
	}
	// Follow symlinks
	real, err := filepath.EvalSymlinks(exe)
	if err != nil {
		return "", err
	}
	dir := filepath.Dir(real)
	// Walk up to find tools/ directory
	for {
		if _, err := os.Stat(filepath.Join(dir, "tools")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	return "", fmt.Errorf("cannot find project root (tools/ not found)")
}

// ── Data loading ──

func loadSections(rootDir, baseDir string) []Section {
	reportBin := filepath.Join(rootDir, "tools", "report")
	cmd := exec.Command(reportBin, baseDir, "--list-sections", "--no-color")
	out, err := cmd.Output()
	if err != nil {
		fmt.Fprintf(os.Stderr, "error loading sections: %v\n", err)
		return nil
	}

	var sections []Section
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		parts := strings.SplitN(line, "\t", 2)
		if len(parts) == 2 && parts[0] != "" {
			sections = append(sections, Section{Key: parts[0], Marker: parts[1]})
		}
	}
	return sections
}

func loadReport(rootDir, baseDir string) string {
	reportBin := filepath.Join(rootDir, "tools", "report")
	cmd := exec.Command(reportBin, baseDir, "--no-color")
	out, err := cmd.Output()
	if err != nil {
		fmt.Fprintf(os.Stderr, "error loading report: %v\n", err)
		return "(report load failed)"
	}
	return string(out)
}

func extractSection(fullReport string, sections []Section, idx int) string {
	if idx < 0 || idx >= len(sections) {
		return ""
	}
	marker := sections[idx].Marker

	// Find start
	start := strings.Index(fullReport, marker)
	if start < 0 {
		return fmt.Sprintf("(section marker not found: %s)", marker)
	}

	var end int
	if idx+1 < len(sections) {
		nextMarker := sections[idx+1].Marker
		end = strings.Index(fullReport[start+len(marker):], nextMarker)
		if end >= 0 {
			end += start + len(marker)
			return fullReport[start:end]
		}
	}
	// Last section: to EOF
	return fullReport[start:]
}

// ── UI ──

func (s *State) refresh() {
	if len(s.Sections) == 0 {
		return
	}
	content := extractSection(s.FullReport, s.Sections, s.CurrentSection)
	s.ReportView.SetText(content)
	s.ReportView.ScrollToBeginning()

	// Status bar
	sec := s.Sections[s.CurrentSection]
	status := fmt.Sprintf(
		" [yellow][%d/%d][white] %s [gray]│[white] n/p:next/prev  g:jump  a:add  r:reload  ?:help  q:quit",
		s.CurrentSection+1, len(s.Sections), sec.Key,
	)
	s.StatusBar.SetText(status)
}

func (s *State) handleInput(event *tcell.EventKey) *tcell.EventKey {
	switch event.Rune() {
	case 'n':
		if s.CurrentSection < len(s.Sections)-1 {
			s.CurrentSection++
			s.refresh()
		}
		return nil
	case 'p':
		if s.CurrentSection > 0 {
			s.CurrentSection--
			s.refresh()
		}
		return nil
	case 'q':
		s.App.Stop()
		return nil
	case 'a':
		s.App.Suspend(func() {
			cmd := exec.Command(filepath.Join(s.RootDir, "tools", "add-ui.sh"), "--base", s.BaseDir)
			cmd.Stdin = os.Stdin
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			_ = cmd.Run()
		})
		s.StatusBar.SetText(" Reloading...")
		s.App.Draw()
		go func() {
			report := loadReport(s.RootDir, s.BaseDir)
			s.App.QueueUpdateDraw(func() {
				s.FullReport = report
				s.refresh()
			})
		}()
		return nil
	case 'r':
		s.StatusBar.SetText(" Reloading...")
		s.App.Draw()
		go func() {
			report := loadReport(s.RootDir, s.BaseDir)
			s.App.QueueUpdateDraw(func() {
				s.FullReport = report
				s.refresh()
			})
		}()
		return nil
	case 'g':
		s.showSectionJump()
		return nil
	case '?':
		s.showHelp()
		return nil
	}
	switch event.Key() {
	case tcell.KeyTab:
		if s.CurrentSection < len(s.Sections)-1 {
			s.CurrentSection++
			s.refresh()
		}
		return nil
	case tcell.KeyBacktab:
		if s.CurrentSection > 0 {
			s.CurrentSection--
			s.refresh()
		}
		return nil
	case tcell.KeyEscape:
		// If a modal is open, Pages handles it. Otherwise pass through.
		if name, _ := s.Pages.GetFrontPage(); name != "main" {
			s.Pages.SwitchToPage("main")
			return nil
		}
	}
	return event
}

// ── Modals ──

func (s *State) showSectionJump() {
	list := tview.NewList()
	list.SetBorder(true).SetTitle(" Jump to Section ")
	for i, sec := range s.Sections {
		idx := i
		list.AddItem(sec.Key, "", 0, func() {
			s.CurrentSection = idx
			s.refresh()
			s.Pages.SwitchToPage("main")
			s.Pages.RemovePage("jump")
		})
	}
	list.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		if event.Key() == tcell.KeyEscape {
			s.Pages.SwitchToPage("main")
			s.Pages.RemovePage("jump")
			return nil
		}
		return event
	})

	// Center the list
	flex := tview.NewFlex().
		AddItem(nil, 0, 1, false).
		AddItem(tview.NewFlex().SetDirection(tview.FlexRow).
			AddItem(nil, 0, 1, false).
			AddItem(list, 0, 8, true).
			AddItem(nil, 0, 1, false),
			0, 3, true).
		AddItem(nil, 0, 1, false)

	s.Pages.AddPage("jump", flex, true, true)
}

func (s *State) showHelp() {
	help := tview.NewTextView().
		SetDynamicColors(true).
		SetTextAlign(tview.AlignLeft)
	help.SetBorder(true).SetTitle(" Help ")
	help.SetText(`[yellow]Navigation[white]
  n / Tab          next section
  p / Shift+Tab    previous section
  g                jump to section (list)
  ↑↓ PgUp PgDn    scroll report

[yellow]Actions[white]
  a                add transaction (expense/income/move/plan)
  r                reload report

[yellow]Other[white]
  ?                this help
  q / Ctrl+C       quit

[yellow]Report is read from BQN engine.[white]
Writes go through the Go editor (safe append).`)

	help.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		if event.Key() == tcell.KeyEscape || event.Rune() == '?' || event.Rune() == 'q' {
			s.Pages.SwitchToPage("main")
			s.Pages.RemovePage("help")
			return nil
		}
		return event
	})

	// Center the help box
	flex := tview.NewFlex().
		AddItem(nil, 0, 1, false).
		AddItem(tview.NewFlex().SetDirection(tview.FlexRow).
			AddItem(nil, 0, 1, false).
			AddItem(help, 17, 1, true).
			AddItem(nil, 0, 1, false),
			0, 3, true).
		AddItem(nil, 0, 1, false)

	s.Pages.AddPage("help", flex, true, true)
}
