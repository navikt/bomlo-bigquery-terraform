
# Make workload pool
resource "google_iam_workload_identity_pool" "dbt-workload-pool" {
  workload_identity_pool_id = "bomlo-dbt-identity-pool2"
  display_name              = "Bømlo dbt identity pool"
  description               = "Identity pool for dbt from bomlo-dbt GitHub project"
  project                   = var.project_id
}

# Make provider for GitHub OIDC in the workload pool
resource "google_iam_workload_identity_pool_provider" "github-provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.dbt-workload-pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "dbt-github-provider"
  display_name                       = "OIDC provider for bomlo-dbt repo"

  attribute_mapping = {
    "google.subject"="assertion.sub"
    "attribute.actor"="assertion.actor"
    "attribute.repository"="assertion.repository"
    "attribute.repository_owner"="assertion.repository_owner"
  }

  attribute_condition = "assertion.repository == \"${var.repo_full_name}\""

  oidc {
    issuer_uri="https://token.actions.githubusercontent.com"
  } 
}

# Grant roles to the workload pool
resource "google_project_iam_member" "dbt-workload-pool-grants" {
  for_each = toset(var.grants)
  project  = var.project_id
  role     = each.value
  member   = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.dbt-workload-pool.name}/attribute.repository/${var.repo_full_name}"

  depends_on = [ google_iam_workload_identity_pool_provider.github-provider ]
}

output "workpool-principalSet" {
  value = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.dbt-workload-pool.name}/attribute.repository/${var.repo_full_name}"
}