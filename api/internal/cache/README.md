# Cache Package

Production-ready Valkey (Redis-compatible) caching layer for the Regal Recovery Go backend.

## Overview

This package provides cache-aside pattern implementations using Valkey, with automatic TTL management and JSON serialization.

## Components

### Valkey Client (`valkey.go`)

Low-level Valkey client wrapper using `github.com/valkey-io/valkey-go`:
- Connection management
- Basic operations: Get, Set, Delete
- Error wrapping with context

**Usage:**
```go
client, err := cache.NewValkeyClient("localhost:6379")
if err != nil {
    log.Fatal(err)
}
defer client.Close()

// Set with TTL
err = client.Set(ctx, "user:123", "data", 5*time.Minute)

// Get
val, err := client.Get(ctx, "user:123")

// Delete
err = client.Delete(ctx, "user:123")
```

### Streak Cache (`streak_cache.go`)

Cache-aside pattern for streak data:
- 5-minute TTL
- JSON serialization
- Cache miss returns `nil` (no error) -- caller should fall back to DB

**Streak Structure:**
```go
type Streak struct {
    UserID        string    `json:"userId"`
    CurrentDays   int       `json:"currentDays"`
    SobrietyDate  time.Time `json:"sobrietyDate"`
    LongestStreak int       `json:"longestStreak"`
    TotalRelapses int       `json:"totalRelapses"`
}
```

**Usage:**
```go
valkeyClient, _ := cache.NewValkeyClient("localhost:6379")
streakCache := cache.NewStreakCache(valkeyClient)

// Try cache first
streak, err := streakCache.GetStreak(ctx, userID)
if err != nil {
    return err
}
if streak == nil {
    // Cache miss -- fetch from DB
    streak = fetchFromDB(userID)
    // Populate cache
    streakCache.SetStreak(ctx, userID, streak)
}

// Invalidate on update
streakCache.InvalidateStreak(ctx, userID)
```

## Cache Key Naming Convention

- Prefix with entity type: `streak:{userID}`
- Use colon `:` as delimiter for readability
- Keep keys concise but descriptive

## TTL Strategy

| Data Type | TTL | Rationale |
|-----------|-----|-----------|
| Streak | 5 minutes | Real-time updates for active users; balance freshness vs. DB load |
| Dashboard | 5 minutes | TBD (future implementation) |

## Local Development

Start Valkey via Docker Compose:
```bash
make local-up
```

Valkey will be available at `localhost:6379` with:
- 64 MB memory limit
- `allkeys-lru` eviction policy

## Production Considerations

1. **Connection Pooling**: Valkey-go handles connection pooling internally.
2. **Error Handling**: Cache errors should not fail requests; log and fall back to DB.
3. **Serialization**: JSON is used for readability; consider MessagePack for performance-critical paths.
4. **TTL Tuning**: Monitor cache hit rates and adjust TTLs based on access patterns.
5. **Memory Management**: Configure Valkey `maxmemory` and eviction policy in production (LRU recommended).

## Cache Invalidation Patterns

1. **Write-through**: Update DB, then invalidate cache (current implementation)
2. **Write-behind**: Update cache, async DB write (future optimization)
3. **Event-driven**: Listen to domain events and invalidate affected caches

## Future Extensions

- Dashboard cache (`dashboard_cache.go`)
- Rate limiting cache (per-user request counts)
- Session cache (if needed)
