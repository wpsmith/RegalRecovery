// internal/domain/threecircles/version_history.go
package threecircles

import (
	"errors"
	"fmt"
)

// Sentinel errors for version history operations.
var (
	ErrVersionNotFound  = errors.New("version not found")
	ErrEmptyVersionList = errors.New("version list is empty")
	ErrInvalidFromTo    = errors.New("from and to versions must be different")
)

// VersionSummary represents a condensed view of a version snapshot.
type VersionSummary struct {
	VersionNumber int        `json:"versionNumber"`
	ChangedAt     string     `json:"changedAt"` // ISO 8601 timestamp
	ChangeNote    string     `json:"changeNote,omitempty"`
	ChangeType    ChangeType `json:"changeType"`
	InnerCount    int        `json:"innerCount"`
	MiddleCount   int        `json:"middleCount"`
	OuterCount    int        `json:"outerCount"`
}

// VersionDiff represents the difference between two version snapshots.
type VersionDiff struct {
	FromVersion   int          `json:"fromVersion"`
	ToVersion     int          `json:"toVersion"`
	InnerAdded    []CircleItem `json:"innerAdded"`
	InnerRemoved  []CircleItem `json:"innerRemoved"`
	MiddleAdded   []CircleItem `json:"middleAdded"`
	MiddleRemoved []CircleItem `json:"middleRemoved"`
	OuterAdded    []CircleItem `json:"outerAdded"`
	OuterRemoved  []CircleItem `json:"outerRemoved"`
	ItemsMoved    []ItemMove   `json:"itemsMoved"`
}

// ItemMove represents an item that moved between circles.
type ItemMove struct {
	ItemID     string     `json:"itemId"`
	FromCircle CircleType `json:"fromCircle"`
	ToCircle   CircleType `json:"toCircle"`
}

// ListVersionSummaries returns a list of version summaries in reverse chronological order.
func ListVersionSummaries(versions []VersionSnapshot) []VersionSummary {
	summaries := make([]VersionSummary, 0, len(versions))

	for i := len(versions) - 1; i >= 0; i-- {
		v := versions[i]
		summaries = append(summaries, VersionSummary{
			VersionNumber: v.VersionNumber,
			ChangedAt:     v.ChangedAt.Format("2006-01-02T15:04:05Z07:00"),
			ChangeNote:    v.ChangeNote,
			ChangeType:    v.ChangeType,
			InnerCount:    v.InnerCount,
			MiddleCount:   v.MiddleCount,
			OuterCount:    v.OuterCount,
		})
	}

	return summaries
}

// GetVersion returns a specific version snapshot by version number.
func GetVersion(versions []VersionSnapshot, number int) (*VersionSnapshot, error) {
	for i := range versions {
		if versions[i].VersionNumber == number {
			return &versions[i], nil
		}
	}
	return nil, fmt.Errorf("%w: version %d", ErrVersionNotFound, number)
}

// GetLatestVersion returns the most recent version snapshot.
func GetLatestVersion(versions []VersionSnapshot) (*VersionSnapshot, error) {
	if len(versions) == 0 {
		return nil, ErrEmptyVersionList
	}

	// Find the version with the highest version number.
	latest := &versions[0]
	for i := 1; i < len(versions); i++ {
		if versions[i].VersionNumber > latest.VersionNumber {
			latest = &versions[i]
		}
	}

	return latest, nil
}

// CompareVersions returns the diff between two version snapshots.
func CompareVersions(from, to VersionSnapshot) VersionDiff {
	diff := VersionDiff{
		FromVersion:   from.VersionNumber,
		ToVersion:     to.VersionNumber,
		InnerAdded:    []CircleItem{},
		InnerRemoved:  []CircleItem{},
		MiddleAdded:   []CircleItem{},
		MiddleRemoved: []CircleItem{},
		OuterAdded:    []CircleItem{},
		OuterRemoved:  []CircleItem{},
		ItemsMoved:    []ItemMove{},
	}

	// Build item maps for from version.
	fromInner := makeItemMap(from.Snapshot.InnerCircle)
	fromMiddle := makeItemMap(from.Snapshot.MiddleCircle)
	fromOuter := makeItemMap(from.Snapshot.OuterCircle)

	// Build item maps for to version.
	toInner := makeItemMap(to.Snapshot.InnerCircle)
	toMiddle := makeItemMap(to.Snapshot.MiddleCircle)
	toOuter := makeItemMap(to.Snapshot.OuterCircle)

	// Check for added and moved items in inner circle.
	for id, item := range toInner {
		if _, inFromInner := fromInner[id]; !inFromInner {
			// Item is in "to" inner but not in "from" inner.
			if _, inFromMiddle := fromMiddle[id]; inFromMiddle {
				diff.ItemsMoved = append(diff.ItemsMoved, ItemMove{
					ItemID:     id,
					FromCircle: CircleMiddle,
					ToCircle:   CircleInner,
				})
			} else if _, inFromOuter := fromOuter[id]; inFromOuter {
				diff.ItemsMoved = append(diff.ItemsMoved, ItemMove{
					ItemID:     id,
					FromCircle: CircleOuter,
					ToCircle:   CircleInner,
				})
			} else {
				diff.InnerAdded = append(diff.InnerAdded, item)
			}
		}
	}

	// Check for removed items from inner circle.
	for id, item := range fromInner {
		if _, inToInner := toInner[id]; !inToInner {
			if _, inToMiddle := toMiddle[id]; !inToMiddle {
				if _, inToOuter := toOuter[id]; !inToOuter {
					diff.InnerRemoved = append(diff.InnerRemoved, item)
				}
			}
		}
	}

	// Check for added and moved items in middle circle.
	for id, item := range toMiddle {
		if _, inFromMiddle := fromMiddle[id]; !inFromMiddle {
			if _, inFromInner := fromInner[id]; inFromInner {
				diff.ItemsMoved = append(diff.ItemsMoved, ItemMove{
					ItemID:     id,
					FromCircle: CircleInner,
					ToCircle:   CircleMiddle,
				})
			} else if _, inFromOuter := fromOuter[id]; inFromOuter {
				diff.ItemsMoved = append(diff.ItemsMoved, ItemMove{
					ItemID:     id,
					FromCircle: CircleOuter,
					ToCircle:   CircleMiddle,
				})
			} else {
				diff.MiddleAdded = append(diff.MiddleAdded, item)
			}
		}
	}

	// Check for removed items from middle circle.
	for id, item := range fromMiddle {
		if _, inToMiddle := toMiddle[id]; !inToMiddle {
			if _, inToInner := toInner[id]; !inToInner {
				if _, inToOuter := toOuter[id]; !inToOuter {
					diff.MiddleRemoved = append(diff.MiddleRemoved, item)
				}
			}
		}
	}

	// Check for added and moved items in outer circle.
	for id, item := range toOuter {
		if _, inFromOuter := fromOuter[id]; !inFromOuter {
			if _, inFromInner := fromInner[id]; inFromInner {
				diff.ItemsMoved = append(diff.ItemsMoved, ItemMove{
					ItemID:     id,
					FromCircle: CircleInner,
					ToCircle:   CircleOuter,
				})
			} else if _, inFromMiddle := fromMiddle[id]; inFromMiddle {
				diff.ItemsMoved = append(diff.ItemsMoved, ItemMove{
					ItemID:     id,
					FromCircle: CircleMiddle,
					ToCircle:   CircleOuter,
				})
			} else {
				diff.OuterAdded = append(diff.OuterAdded, item)
			}
		}
	}

	// Check for removed items from outer circle.
	for id, item := range fromOuter {
		if _, inToOuter := toOuter[id]; !inToOuter {
			if _, inToInner := toInner[id]; !inToInner {
				if _, inToMiddle := toMiddle[id]; !inToMiddle {
					diff.OuterRemoved = append(diff.OuterRemoved, item)
				}
			}
		}
	}

	return diff
}

// RestoreVersion restores a circle set from a target version snapshot.
// It replaces the current circles with the target version's circles,
// creates a NEW version (does not rewind history), and returns the updated set and snapshot.
// Draft sets become active on restore.
func RestoreVersion(currentSet *CircleSet, targetVersion VersionSnapshot, changeNote string) (*CircleSet, *VersionSnapshot, error) {
	// Validate change note length.
	if len(changeNote) > 500 {
		return nil, nil, ErrChangeNoteTooLong
	}

	// Restore the set from the snapshot.
	restored := RestoreFromSnapshot(currentSet, &targetVersion)

	// If the current set is a draft, make it active after restore.
	if currentSet.Status == StatusDraft {
		restored.Status = StatusActive
	}

	// Create a new version snapshot for the restore operation.
	snapshot, err := CreateSnapshotForRestore(restored, targetVersion.VersionNumber, changeNote)
	if err != nil {
		return nil, nil, fmt.Errorf("creating restore snapshot: %w", err)
	}

	return restored, snapshot, nil
}

// makeItemMap creates a map of item ID to CircleItem for quick lookup.
func makeItemMap(items []CircleItem) map[string]CircleItem {
	m := make(map[string]CircleItem, len(items))
	for _, item := range items {
		m[item.ItemID] = item
	}
	return m
}
