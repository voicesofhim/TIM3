# Process IDs (PIDs)

Central place to track TEST/PROD PIDs. Update this after (re)deploys.

## TEST (development)
- Coordinator: uNhmrUij4u6ZZr_39BDI5E2G2afkit8oC7q4vAtRskM (previous)
- Lock Manager: MWxRVsCDoSzQ0MhG4_BWkYs0fhcULB-OO3f2t1RlBAs (previous)
- Token Manager: DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw (previous)
- State Manager: K2FjwiTmncglx0pISNMft5-SngxW-HUjs9sctzmXtU4 (previous)
- Mock USDA: u8DzisIMWnrfGa6nlQvf1J79kYkv8uWjDeXZ489UMXQ (previous)

Update these with fresh PIDs when redeploying via `contracts/loads/*`.

## PROD (if applicable)
- Coordinator: 
- Lock Manager: 
- Token Manager: 
- State Manager: 
- USDA (real): 

Notes:
- Keep PIDs out of source where possible; wire them only in the designated config/verify scripts.
- If you change PIDs, update `configure-integration.lua`, `verify-e2e.lua`, and `verify-test-processes.lua` to match.
