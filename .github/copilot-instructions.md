# Workspace Guidance

This workspace contains Radius Bicep demos for .NET applications, from local KIND to Azure Kubernetes Service. Read `README.md` before changing the workspace. It is the source for workflows, setup, deployment, and Recipe guidance.

## Radius

For every Radius or `rad` question or change, verify current behavior against the stable documentation at https://docs.radapp.io. Do not use edge documentation. Preserve the injected `application` and `environment` parameters and existing Radius type versions unless an upgrade is deliberate and verified.

Use the existing manifests as implementation references. Keep application definitions, Radius Recipes, and Azure infrastructure separate.

## Safety

The Azure SQL Recipe, Azure Container Registry, and role assignments are intentionally permissive demo configurations. Do not present them as production guidance or broaden access without a clear reason. Never expose values returned by `listSecrets()`.

Keep the IPv4 only KIND setup and its LoadBalancer service assumptions intact. Consult `docs/faq.md` for local deployment engine or Azure authentication network issues.

## Conventions

Follow `.editorconfig` and existing file style. Avoid formatting only changes. Preserve resource API versions unless an update is intentional and verified. Write new documentation and user facing text in English without hyphens. Update `README.md` when a documented workflow, setup requirement, Recipe, or deployment behavior changes.
