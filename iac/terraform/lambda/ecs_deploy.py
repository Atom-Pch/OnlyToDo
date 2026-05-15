# lambda/ecs_deploy.py
import boto3
import os

ecs = boto3.client("ecs")

# Refactored: Map ECR repository names to BOTH their target Cluster and Service
REPO_MAP = {
    os.environ["FRONTEND_REPO_NAME"]: {
        "cluster": os.environ["APP_CLUSTER_NAME"],
        "service": os.environ["FRONTEND_SERVICE_NAME"],
    },
    os.environ["BACKEND_REPO_NAME"]: {
        "cluster": os.environ["APP_CLUSTER_NAME"],
        "service": os.environ["BACKEND_SERVICE_NAME"],
    },
    os.environ["PROM_REPO_NAME"]: {
        "cluster": os.environ["MNO_CLUSTER_NAME"],
        "service": os.environ["MNO_SERVICE_NAME"],
    },
    os.environ["GRAF_REPO_NAME"]: {
        "cluster": os.environ["MNO_CLUSTER_NAME"],
        "service": os.environ["MNO_SERVICE_NAME"],
    },
}

def lambda_handler(event, context):
    print(f"Received event: {event}")

    detail = event.get("detail", {})
    repo_name = detail.get("repository-name")
    image_tag = detail.get("image-tag")

    if image_tag != "latest":
        print(f"Ignoring push for tag: {image_tag}")
        return {"status": "ignored", "reason": "Not 'latest' tag"}

    # Fetch the target routing config for this specific repo
    target = REPO_MAP.get(repo_name)
    if not target:
        print(f"No ECS service mapped for repo: {repo_name}")
        return {"status": "error", "reason": "Unmapped repository"}

    cluster_name = target["cluster"]
    service_name = target["service"]

    print(f"Triggering force deployment for service: '{service_name}' in cluster: '{cluster_name}'")
    try:
        ecs.update_service(
            cluster=cluster_name, 
            service=service_name, 
            forceNewDeployment=True
        )
        print("Deployment triggered successfully!")
        return {"status": "success", "cluster": cluster_name, "service": service_name}
    except Exception as e:
        print(f"Error updating service: {str(e)}")
        raise e
