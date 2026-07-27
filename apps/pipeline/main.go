package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

// ResourceRequest represents the incoming Kratix resource request
type ResourceRequest struct {
	APIVersion string            `json:"apiVersion"`
	Kind       string            `json:"kind"`
	Metadata   Metadata          `json:"metadata"`
	Spec       map[string]interface{} `json:"spec"`
}

type Metadata struct {
	Name      string            `json:"name"`
	Namespace string            `json:"namespace"`
	Labels    map[string]string `json:"labels,omitempty"`
}

func main() {
	log.Println("🏀 NBA Service Pipeline — starting")

	// Kratix mounts the resource request at /kratix/input/object.yaml
	inputPath := "/kratix/input/object.yaml"
	outputDir := "/kratix/output"

	inputData, err := os.ReadFile(inputPath)
	if err != nil {
		log.Fatalf("Failed to read input: %v", err)
	}

	var request ResourceRequest
	if err := json.Unmarshal(inputData, &request); err != nil {
		log.Fatalf("Failed to parse input: %v", err)
	}

	name := request.Metadata.Name
	namespace := getStringField(request.Spec, "namespace", "kratix-demo")
	port := getIntField(request.Spec, "port", 8080)
	team := getStringField(request.Spec, "team", "platform")
	environment := getStringField(request.Spec, "environment", "dev")
	image := getStringField(request.Spec, "image", fmt.Sprintf("kratix-demo/%s:latest", name))
	replicas := getIntField(request.Spec, "replicas", 1)

	log.Printf("Generating resources for: name=%s namespace=%s port=%d team=%s env=%s", name, namespace, port, team, environment)

	// Generate Deployment
	deployment := generateDeployment(name, namespace, image, port, replicas, team, environment)
	if err := writeOutput(outputDir, fmt.Sprintf("%s-deployment.yaml", name), deployment); err != nil {
		log.Fatalf("Failed to write deployment: %v", err)
	}

	// Generate Service
	service := generateService(name, namespace, port, team, environment)
	if err := writeOutput(outputDir, fmt.Sprintf("%s-service.yaml", name), service); err != nil {
		log.Fatalf("Failed to write service: %v", err)
	}

	// Generate ConfigMap
	configMap := generateConfigMap(name, namespace, team, environment)
	if err := writeOutput(outputDir, fmt.Sprintf("%s-configmap.yaml", name), configMap); err != nil {
		log.Fatalf("Failed to write configmap: %v", err)
	}

	log.Println("✅ Pipeline complete — resources generated")
}

func generateDeployment(name, namespace, image string, port, replicas int, team, environment string) string {
	return fmt.Sprintf(`apiVersion: apps/v1
kind: Deployment
metadata:
  name: %s
  namespace: %s
  labels:
    app: %s
    app.kubernetes.io/name: %s
    app.kubernetes.io/part-of: nba-platform
    app.kubernetes.io/managed-by: kratix
    team: %s
    environment: %s
spec:
  replicas: %d
  selector:
    matchLabels:
      app: %s
  template:
    metadata:
      labels:
        app: %s
        app.kubernetes.io/name: %s
        team: %s
        environment: %s
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
      containers:
        - name: %s
          image: %s
          ports:
            - containerPort: %d
          env:
            - name: PORT
              value: "%d"
            - name: APP_VERSION
              value: "1.0.0"
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
          securityContext:
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
          readinessProbe:
            httpGet:
              path: /health
              port: %d
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: %d
            initialDelaySeconds: 10
            periodSeconds: 30
`, name, namespace, name, name, team, environment,
		replicas, name, name, name, team, environment,
		name, image, port, port, port, port)
}

func generateService(name, namespace string, port int, team, environment string) string {
	return fmt.Sprintf(`apiVersion: v1
kind: Service
metadata:
  name: %s
  namespace: %s
  labels:
    app: %s
    app.kubernetes.io/name: %s
    app.kubernetes.io/managed-by: kratix
    team: %s
    environment: %s
spec:
  selector:
    app: %s
  ports:
    - port: %d
      targetPort: %d
      protocol: TCP
  type: ClusterIP
`, name, namespace, name, name, team, environment, name, port, port)
}

func generateConfigMap(name, namespace, team, environment string) string {
	return fmt.Sprintf(`apiVersion: v1
kind: ConfigMap
metadata:
  name: %s-config
  namespace: %s
  labels:
    app: %s
    app.kubernetes.io/name: %s
    app.kubernetes.io/managed-by: kratix
    team: %s
    environment: %s
data:
  SERVICE_NAME: %s
  TEAM: %s
  ENVIRONMENT: %s
  MANAGED_BY: kratix
`, name, namespace, name, name, team, environment, name, team, environment)
}

func writeOutput(dir, filename, content string) error {
	path := filepath.Join(dir, filename)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, []byte(content), 0o644)
}

func getStringField(spec map[string]interface{}, key, fallback string) string {
	if val, ok := spec[key]; ok {
		if s, ok := val.(string); ok {
			return strings.TrimSpace(s)
		}
	}
	return fallback
}

func getIntField(spec map[string]interface{}, key string, fallback int) int {
	if val, ok := spec[key]; ok {
		switch v := val.(type) {
		case float64:
			return int(v)
		case int:
			return v
		}
	}
	return fallback
}
