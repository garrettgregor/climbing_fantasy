# Postman Notes

## Internal API collection (generated)

- `collections/climbing_fantasy_api.postman_collection.json`
- `environments/climbing_fantasy_local.postman_environment.json`
- `environments/climbing_fantasy_mock.postman_environment.json`

Regenerate with:

```bash
ruby scripts/postman/build_postman_assets.rb
```

## External IFSC/USAC shape collection (manual)

- `collections/external_results_apis.postman_collection.json`
- `environments/external_results_apis_local.postman_environment.json`

Use this collection to inspect payload shapes for undocumented external endpoints.

Workflow:

1. Import the external collection + environment.
2. Run `USAC > Get Session Cookie` or `IFSC > Get Session Cookie` first.
3. Run endpoint requests (`events`, `events/:id/result/:dcat_id`, `category_rounds/:id/results`, etc.).

The session requests store cookie headers in collection variables, so subsequent requests can run without manual cookie copy/paste.
Each request also includes a saved example response so payload shape is visible before sending any calls.

To sync these external assets to the Postman Team Workspace:

```bash
bash scripts/postman/sync_external_results_resources.sh
```
