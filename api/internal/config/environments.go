// internal/config/environments.go
package config

// IsLocal returns true if the application is running in the local development environment.
func (c Config) IsLocal() bool {
	return c.Environment == "local"
}

// IsStaging returns true if the application is running in the staging environment.
func (c Config) IsStaging() bool {
	return c.Environment == "staging"
}

// IsProd returns true if the application is running in the production environment.
func (c Config) IsProd() bool {
	return c.Environment == "prod"
}
