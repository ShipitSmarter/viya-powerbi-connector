/**
 * Viya Power BI Connector
 *
 * Custom Power Query connector that wraps OData.Feed with Viya PAT authentication.
 * Injects the Personal Access Token as an x-api-pat header on every request.
 *
 * Features:
 * - Appears in Power BI Get Data dialog with Viya branding
 * - Key-based authentication (prompts for PAT)
 * - Full OData query folding ($filter, $select, $orderby, $top, $skip, $count)
 * - Auto-discovers entity sets from $metadata
 * - Supports On-Premises Data Gateway (TestConnection handler)
 */
section Viya;

//
// Exported function — the public API of this connector.
// Takes a tenant name (primary) and an optional URL override (advanced), returns a navigation table.
//
[DataSource.Kind="Viya", Publish="Viya.Publish"]
shared Viya.Feed = Value.ReplaceType(
    ViyaImpl,
    ViyaFeedType
);

//
// Function type with documentation metadata.
// tenant is the primary parameter; url is an optional advanced override.
//
ViyaFeedType = type function (
    tenant as (type text meta [
        Documentation.FieldCaption = "Tenant Name",
        Documentation.FieldDescription = "Your Viya tenant name (e.g. 'acme'). The connector will connect to https://{tenant}.viya.me/api/shipping/odata/v1",
        Documentation.SampleValues = {"acme"}
    ]),
    optional url as (type nullable text meta [
        Documentation.FieldCaption = "OData Service URL (Advanced)",
        Documentation.FieldDescription = "Override the default URL. Leave blank for standard Viya connections.",
        Documentation.SampleValues = {"https://acme.viya.me/api/shipping/odata/v1"}
    ])
) as table meta [
    Documentation.Name = "Viya",
    Documentation.LongDescription = "Connects to Viya OData endpoints using Personal Access Token authentication.",
    Documentation.Examples = {[
        Description = "Connect using tenant name",
        Code = "Viya.Feed(""acme"")",
        Result = "A navigation table with available entity sets (Consignments, Shipments, etc.)"
    ]}
];

//
// Implementation — derives the effective OData URL from the tenant name (or uses the
// optional url override), then reads the PAT from credentials and passes it as the
// x-api-pat header via OData.Feed's second parameter (headers record).
//
// OData.Feed pointed at a service root returns a navigation table automatically
// by reading $metadata — no need to hardcode entity sets.
//
ViyaImpl = (tenant as text, optional url as nullable text) as table =>
    let
        effectiveUrl = if url <> null and url <> "" then url else "https://" & tenant & ".viya.me/api/shipping/odata/v1",
        pat = Extension.CurrentCredential()[Key],
        headers = [#"x-api-pat" = pat],
        source = OData.Feed(
            effectiveUrl,
            headers,
            [
                ODataVersion = 4,
                MoreColumns = true
            ]
        )
    in
        source;

//
// Data Source Kind definition.
// - Key authentication: shows a single "Personal Access Token" text field in the credentials dialog.
// - TestConnection: required for On-Premises Data Gateway support (scheduled refresh).
//   For multi-parameter connectors, dataSourcePath is a JSON string — parse it to extract fields.
//
Viya = [
    TestConnection = (dataSourcePath) =>
        let
            json = Json.Document(dataSourcePath),
            tenant = json[tenant],
            url = if Record.HasFields(json, "url") then json[url] else null
        in
            { "Viya.Feed", tenant, url },
    Authentication = [
        Key = [
            KeyLabel = "Personal Access Token",
            Label = "Viya PAT"
        ]
    ],
    Label = "Viya"
];

//
// Publish record — controls how the connector appears in the Get Data dialog.
//
Viya.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = {
        "Viya",
        "Connect to Viya OData feeds using Personal Access Token authentication"
    },
    LearnMoreUrl = "https://docs.viya.me",
    SourceImage = Viya.Icons,
    SourceTypeImage = Viya.Icons
];

//
// Icon definitions at multiple resolutions for crisp display at all DPI levels.
//
Viya.Icons = [
    Icon16 = {
        Extension.Contents("Viya16.png"),
        Extension.Contents("Viya20.png"),
        Extension.Contents("Viya24.png"),
        Extension.Contents("Viya32.png")
    },
    Icon32 = {
        Extension.Contents("Viya32.png"),
        Extension.Contents("Viya40.png"),
        Extension.Contents("Viya48.png"),
        Extension.Contents("Viya64.png")
    }
];
