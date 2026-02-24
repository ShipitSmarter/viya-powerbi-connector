# Viya Power BI Connector

[![Latest Release](https://img.shields.io/github/v/release/ShipitSmarter/viya-powerbi-connector)](https://github.com/ShipitSmarter/viya-powerbi-connector/releases/latest)
[![Download Viya.mez](https://img.shields.io/badge/download-Viya.mez-blue)](https://github.com/ShipitSmarter/viya-powerbi-connector/releases/latest/download/Viya.mez)

Custom Power Query connector for connecting Power BI (and Excel) to Viya OData endpoints with Personal Access Token (PAT) authentication.

## Why a custom connector?

Power BI's built-in OData connector does not support custom authentication headers. Viya's OData API requires a `x-api-pat` header on every request — a credential format that the native connector cannot provide.

This custom connector solves that by:

- Prompting the user for a PAT via Power BI's built-in **Key** credential dialog
- Injecting `x-api-pat` as a request header on every call to `OData.Feed`
- Fully supporting OData **query folding** — filters, column selection, sorting, and paging are pushed down to the server rather than fetched client-side

## Installation

### Power BI Desktop

1. Download the latest `Viya.mez` from [GitHub Releases](https://github.com/ShipitSmarter/viya-powerbi-connector/releases/latest/download/Viya.mez)
2. Copy it to `[My Documents]\Power BI Desktop\Custom Connectors\` (create the folder if it doesn't exist)
3. In Power BI Desktop, go to **File → Options and settings → Options → Security** and set _Data Extensions_ to **Allow any extension to load without validation or warning**
4. Restart Power BI Desktop

> **Note:** The connector is currently unsigned. A future version will be signed with a code signing certificate, which will allow you to configure it as a trusted connector instead of lowering the security settings above.

## Usage

### Connecting to data

1. In Power BI Desktop, click **Get Data** and search for **Viya**
2. Select **Viya** and click **Connect**
3. Enter your **tenant name** (e.g. `acme`) — the connector will connect to `https://{tenant}.viya.me/api/shipping/odata/v1`
4. For non-standard environments (e.g. test or staging), expand the **Advanced** section and enter a full URL in the **OData Service URL** field to override the default
5. When prompted for credentials, enter your **Personal Access Token** in the _Key_ field
6. Click **Connect** — the navigator will show all available entity sets
7. Select the entity sets you want and click **Load** (or **Transform Data** to apply filters first)

### Available entity sets

| Entity Set      | Description                                  |
|-----------------|----------------------------------------------|
| Consignments    | Shipment consignment records                 |
| Shipments       | Individual shipment details                  |
| TrackingEvents  | Tracking event history per shipment          |
| HandlingUnits   | Handling unit (parcel/pallet) records        |

### Query folding

The connector passes all Power Query transformations back to the OData service as URL parameters, so only the rows and columns you actually need are fetched from the server.

| Power Query operation | OData parameter  |
|-----------------------|------------------|
| Filter rows           | `$filter`        |
| Select columns        | `$select`        |
| Sort rows             | `$orderby`       |
| Take top N rows       | `$top`           |
| Skip N rows           | `$skip`          |
| Count rows            | `$count`         |

Query folding is automatic — apply filters and column selections in Power Query Editor and the generated OData URL will reflect them.

### Example: filtered consignment query

In Power Query Editor, filtering the **Consignments** table to a specific date range generates a folded OData request like:

```
GET https://acme.viya.me/api/shipping/odata/v1/Consignments
    ?$filter=CreatedAt ge 2025-01-01T00:00:00Z and CreatedAt lt 2025-02-01T00:00:00Z
    &$select=Id,Reference,Status,CreatedAt
    &$orderby=CreatedAt desc
    &$top=1000
```

No data outside the filter range is transferred.

## How it works

1. The user enters their **tenant name** in the connector dialog (e.g. `acme`). An expandable **Advanced** section offers an optional **OData Service URL** field to override the default for non-standard environments
2. The connector builds the effective OData URL: `https://{tenant}.viya.me/api/shipping/odata/v1`
3. Power Query prompts for credentials using **Key** authentication — a single text field labelled _Personal Access Token_
4. At runtime, the connector reads the stored PAT via `Extension.CurrentCredential()[Key]`
5. It passes the PAT as an `x-api-pat` header in the **second argument** to `OData.Feed(url, headers, options)`
6. `OData.Feed` fetches `$metadata` from the service root and returns a navigation table containing all available entity sets
7. All subsequent queries (entity set data, filters, etc.) inherit the `x-api-pat` header and benefit from OData query folding

## Development

### Prerequisites

- **.NET SDK** — required for `dotnet build Viya.proj`
- **Power Query SDK for VS Code** (Windows only, optional) — for running test queries interactively

### Building

```bash
dotnet build Viya.proj
```

Produces `bin/Viya.mez`.

### Testing

**Interactive (Windows only):**
1. Install the [Power Query SDK](https://marketplace.visualstudio.com/items?itemName=PowerQuery.vscode-powerquery-sdk) extension for VS Code
2. Build the connector (`Ctrl+Shift+B → MakePQX`)
3. Set credentials: Power Query SDK panel → **Set credential** → Viya → Key → enter your PAT
4. Open `Viya.query.pq`, right-click → **Evaluate current power query file**

**Manual:**
Load the built `Viya.mez` into Power BI Desktop (see [Installation](#installation)) and use **Get Data → Viya**.

### Project structure

```
├── src/
│   ├── Viya.pq            # Main connector definition (M section document)
│   ├── Viya.query.pq      # Test query (dev-only, not shipped in .mez)
│   ├── resources.resx     # Localized string resources
│   ├── Viya16.png         # Connector icon — 16×16
│   ├── Viya20.png         # Connector icon — 20×20
│   ├── Viya24.png         # Connector icon — 24×24
│   ├── Viya32.png         # Connector icon — 32×32
│   ├── Viya40.png         # Connector icon — 40×40
│   ├── Viya48.png         # Connector icon — 48×48
│   └── Viya64.png         # Connector icon — 64×64
├── Viya.proj          # MSBuild project (cross-platform)
├── .gitignore         # Excludes build artifacts (bin/, obj/)
└── README.md          # This file
```

## Troubleshooting

### "DataSource.Error: Unable to connect"

- Verify your tenant name is correct (no spaces, no `.viya.me` suffix — just the short name like `acme`)
- Check that the PAT is valid and has not expired
- If connecting to a non-standard environment, ensure the URL override in the **Advanced** section's **OData Service URL** field is correct

### "Expression.Error: The key didn't match any rows in the table"

The navigator returned an entity set name that no longer exists. Refresh the navigator or reconnect to pick up the current `$metadata`.

### Connector does not appear in Get Data

- Confirm `Viya.mez` is in the correct Custom Connectors folder (see [Installation](#installation))
- Confirm the **Allow any extension to load without validation or warning** security setting is enabled
- Restart Power BI Desktop after copying the file

### "Formula.Firewall: Query references other queries"

This is a Power BI privacy firewall error. Go to **File → Options → Privacy** and set the privacy level to **Ignore the Privacy Levels** (for personal use) or configure data source privacy levels appropriately.

### Scheduled refresh fails on Power BI Service / Data Gateway

- Ensure the gateway machine has `Viya.mez` in the Custom Connectors folder and the gateway is configured to allow custom connectors (see [On-Premises Data Gateway](#on-premises-data-gateway))
- Confirm the PAT credential is set on the gateway data source in the Power BI service (**Manage gateways → [data source] → Edit credentials**)
- Check the gateway logs for connection test errors (`TestConnection` is called before each refresh)
