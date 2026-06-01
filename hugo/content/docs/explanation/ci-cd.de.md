---
title: CI/CD
weight: 4
---

Diese Seite beschreibt das CI/CD-Setup des Projekts.

## GitHub Actions

Das folgende Diagramm zeigt die GitHub Actions Workflows.

```plantuml
@startuml
!theme plain
skinparam componentStyle rectangle

' Actors
actor Developer

cloud "GitHub" as GH {
    rectangle "Repository" as Repo {
        file "main branch" as main
        file "Pull Request" as PR
    }
    
    rectangle "GitHub Actions" as Actions {
        rectangle "PR Workflows" as PRWorkflows {
            component "🔄 Server PR Check\n(server-pr.yaml)" as ServerPR
            component "🔄 Proctor PR Check\n(proctor-pr.yaml)" as ProctorPR
            component "🔄 Sentinel PR Check\n(sentinel-pr.yaml)" as SentinelPR
        }
        
        rectangle "Deploy Workflows" as DeployWorkflows {
            component "🚀 Deploy Docs\n(hugo-deploy.yaml)" as HugoDeploy
            component "🎉 Release & Deploy\n(release.yaml)" as Release
        }
        
        component "📦 Auto-Archive\n(auto-archive.yaml)" as AutoArchive
    }
    
    rectangle "GitHub Pages" as Pages
    rectangle "GitHub Releases" as Releases
}

cloud "GitHub Container Registry (ghcr.io)" as GHCR {
    artifact "franklyn-hugo:latest" as HugoImage
    artifact "franklyn-server:latest" as ServerImage
    artifact "franklyn-proctor:latest" as ProctorImage
}

' Force vertical layout
Developer -[hidden]down-> GH
GH -[hidden]down-> GHCR

' PR Workflow triggers
PR --> ServerPR : "paths: server/**"
PR --> ProctorPR : "paths: proctor/**"
PR --> SentinelPR : "paths: sentinel/**"

' Merge/Push triggers
main --> HugoDeploy : "paths: hugo/**"
main --> Release : "[release] or\n[twilight] commit"
PR -[dotted]-> AutoArchive : "closed"

' Outputs
HugoDeploy --> Pages : "Deploy static site"
HugoDeploy .d.> HugoImage : "Push Docker image"

Release --> Releases : "Draft release\n(artifacts)"
Release .d.> ServerImage : "Push Docker image"
Release .d.> ProctorImage : "Push Docker image"

Developer --> PR : "Create PR"
Developer --> main : "Merge PR"

@enduml
```

## Kubernetes-Deployment

Das folgende Diagramm zeigt die Kubernetes-Deployment-Architektur.

```plantuml
@startuml
!theme plain
skinparam componentStyle rectangle

title Kubernetes-Deployment-Architektur

cloud "Internet" as Internet

node "Kubernetes Cluster" as K8s {
    
    rectangle "Ingress (nginx)" as Ingress {
        portin "/api" as api_path
        portin "/proctor" as proctor_path
        portin "/" as root_path
    }
    
    rectangle "Services" as Services {
        component "franklyn-server-service\n:8080" as ServerSvc
        component "franklyn-proctor-service\n:80" as ProctorSvc
        component "franklyn-hugo-service\n:80" as HugoSvc
        component "postgres-service\n:5432" as PostgresSvc
    }
    
    rectangle "Deployments" as Deployments {
        node "franklyn-server" as ServerDep {
            component "franklyn-server\ncontainer :8080" as ServerContainer
        }
        node "franklyn-proctor" as ProctorDep {
            component "franklyn-proctor\ncontainer :80" as ProctorContainer
        }
        node "franklyn-hugo" as HugoDep {
            component "franklyn-hugo\ncontainer :80" as HugoContainer
        }
        node "postgres" as PostgresDep {
            component "postgres:18-alpine\ncontainer :5432" as PostgresContainer
        }
    }
    
    database "postgres-pvc\n(1Gi)" as PVC
    
    rectangle "Konfiguration" as Config {
        file "postgres-config (ConfigMap)\nPOSTGRES_DB: db\nPOSTGRES_USER: app" as PGConfig
        file "postgres-secret (Secret)\nPOSTGRES_PASSWORD" as PGSecret
    }
}

cloud "ghcr.io" as Registry {
    artifact "franklyn-server:latest" as ServerImg
    artifact "franklyn-proctor:latest" as ProctorImg
    artifact "franklyn-hugo:latest" as HugoImg
}

' Externer Traffic-Routing
Internet --> Ingress

api_path --> ServerSvc
proctor_path --> ProctorSvc
root_path --> HugoSvc

' Service zu Deployment-Verbindungen
ServerSvc --> ServerContainer
ProctorSvc --> ProctorContainer
HugoSvc --> HugoContainer
PostgresSvc --> PostgresContainer

' Postgres-Abhängigkeiten
PostgresContainer --> PVC : "mount\n/var/lib/postgresql"
PGConfig --> PostgresContainer : "env vars"
PGConfig --> ServerContainer : "env vars"
PGSecret --> PostgresContainer : "env vars"
PGSecret --> ServerContainer : "env vars"

' Image pulls
Registry -[dotted]-> ServerContainer : "pull"
Registry -[dotted]-> ProctorContainer : "pull"
Registry -[dotted]-> HugoContainer : "pull"

@enduml
```

## Vollständiger CI/CD-Ablauf

```plantuml
@startuml
!theme plain

title Vollständiger CI/CD-Pipeline-Ablauf

|Entwickler|
start
:Feature-Branch erstellen;
:Änderungen vornehmen;
:Pull Request öffnen;

|GitHub Actions|
fork
    :🔄 Server PR Check;
    note right
        - Nix einrichten
        - Postgres starten (docker-compose)
        - Verifizierung durchführen
        - ktlint-Ergebnisse melden
    end note
fork again
    :🔄 Proctor PR Check;
    note right
        - Nix einrichten
        - Verifizierung durchführen
        - eslint-Ergebnisse melden
    end note
fork again
    :🔄 Sentinel PR Check;
    note right
        - Nix einrichten
        - Verifizierung durchführen
    end note
end fork

|Entwickler|
:PR reviewen & genehmigen;
:In main mergen;

|GitHub Actions|
split
    :📦 Gemergten Branch archivieren;
    note right
        Branch umbenennen zu
        archived/{branch_name}
    end note
    kill
split again
    fork
        if (hugo/** geändert?) then (ja)
            :🚀 Docs deployen;
            :Hugo bauen (Pages + Docker);
            :Auf GitHub Pages deployen;
            :franklyn-hugo auf ghcr.io pushen;
        endif
    fork again
        if (Commit enthält [release] oder [twilight]?) then (ja)
            :🏷️ Version taggen;
            
            fork
                :🏗️ Sentinel bauen;
                :Binary & .deb bauen;
            fork again
                :🏗️ Server bauen;
                :JAR bauen;
            fork again
                :🏗️ Proctor bauen;
                :Dist-Archiv bauen;
            end fork
            
            fork
                :🐳 Docker-Images bauen & veröffentlichen;
                note right
                    Auf ghcr.io pushen:
                    - franklyn-server
                    - franklyn-proctor
                end note
            fork again
                :🎉 GitHub Release erstellen;
                note right
                    Artefakte anhängen:
                    - Sentinel-Binary
                    - Sentinel .deb
                    - Server JAR
                    - Proctor-Archiv
                end note
            end fork
        endif
    end fork
end split

|Kubernetes|
:Neueste Images von ghcr.io pullen;
:Im Cluster deployen;
note right
    Services:
    - franklyn-server (/api)
    - franklyn-proctor (/proctor)  
    - franklyn-hugo (/)
    - postgres (intern)
end note

stop

@enduml
```
