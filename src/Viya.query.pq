/**
 * Test query file for local development.
 * This file is NOT included in the .mez output — it's used only for testing
 * via the Power Query SDK "Evaluate current file" command.
 *
 * Usage:
 * 1. Build the connector (Ctrl+Shift+B → MakePQX)
 * 2. Set credentials via Power Query SDK → Set credential → Viya → Key
 * 3. Replace the tenant name below with your Viya tenant
 * 4. Right-click this file → Evaluate current power query file
 */

// --- Basic test: connect to service root, returns navigation table ---
let
    Source = Viya.Feed("acme"),
    // --- Advanced: connect using a custom URL (e.g. test environment) ---
    // Source = Viya.Feed("acme", "https://acme.test.viya.me/api/shipping/odata/v1"),
    // Uncomment one of the lines below to test a specific entity set:
    // Consignments = Source{[Name="Consignments"]}[Data],
    // Shipments = Source{[Name="Shipments"]}[Data],
    // TrackingEvents = Source{[Name="TrackingEvents"]}[Data],
    // HandlingUnits = Source{[Name="HandlingUnits"]}[Data],
    Result = Source
in
    Result
