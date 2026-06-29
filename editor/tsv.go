package main

import (
	"bufio"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"strings"
	"time"
)

type Row struct {
	LineNum   int
	Raw       string
	Fields    []string
	IsComment bool
	IsEmpty   bool
}

type TSVFile struct {
	Path    string
	Rows    []Row
	ModTime time.Time
	Size    int64
	SHA256  string
}

func ReadTSV(path string) (*TSVFile, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("open tsv %s: %w", path, err)
	}
	defer file.Close()

	stat, err := file.Stat()
	if err != nil {
		return nil, fmt.Errorf("stat tsv %s: %w", path, err)
	}

	h := sha256.New()
	tee := io.TeeReader(file, h)

	var rows []Row
	scanner := bufio.NewScanner(tee)
	lineNum := 0
	for scanner.Scan() {
		lineNum++
		raw := strings.TrimSuffix(scanner.Text(), "\r")
		isComment := strings.HasPrefix(raw, "#") || strings.HasPrefix(raw, "\\")
		isEmpty := strings.TrimSpace(raw) == ""

		var fields []string
		if !isComment && !isEmpty {
			fields = strings.Split(raw, "\t")
		}

		rows = append(rows, Row{
			LineNum:   lineNum,
			Raw:       raw,
			Fields:    fields,
			IsComment: isComment,
			IsEmpty:   isEmpty,
		})
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("scan tsv %s: %w", path, err)
	}

	return &TSVFile{
		Path:    path,
		Rows:    rows,
		ModTime: stat.ModTime(),
		Size:    stat.Size(),
		SHA256:  hex.EncodeToString(h.Sum(nil)),
	}, nil
}

func (t *TSVFile) CheckStale() error {
	stat, err := os.Stat(t.Path)
	if err != nil {
		return fmt.Errorf("stat check %s: %w", t.Path, err)
	}
	if stat.Size() != t.Size || stat.ModTime().After(t.ModTime) {
		file, err := os.Open(t.Path)
		if err != nil {
			return err
		}
		defer file.Close()
		h := sha256.New()
		if _, err := io.Copy(h, file); err != nil {
			return err
		}
		currHash := hex.EncodeToString(h.Sum(nil))
		if currHash != t.SHA256 {
			return fmt.Errorf("file %s is stale", t.Path)
		}
	}
	return nil
}
