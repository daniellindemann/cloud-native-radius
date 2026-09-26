# Demos - DE

## Prep

- Kind environment
    - Kind cluster wird automatisch mit Devcontainer bereitgestellt
- Azure
    - Azure Ressourcen: [Azure Environment - AKS + ACR](README.md#azure-environment---aks--acr)
    - Azure Service Principal: [Azure Environment - Service Principal](README.md#azure-environment---service-principal)
- Radius Recipes in Container Registry bereitstellen
    - Bereitgestellte ACR aus Azure Setup benutzen
    - Script [recipes/push-recipe-to-acr.sh](recipes/push-recipe-to-acr.sh) zum hochladen des *sqldatabase* Recipe für Azure SQL benutzen

        ```bash
        recipes/push-recipe-to-acr.sh \
            --acr <registry-name>.azurecr.io \
            --file recipes/azure/sqldatabase.bicep \
            --target br:<registry-name>.azurecr.io/radius-recipes/sqldatabase:0.60.2
        ```

> **INFO**
> Um sicherzustellen, dass das System "clean" ist, folgende Befehle ausführen:
> - Kind Cluster Reset: `setup/kind/reset/kind.sh`
> - Radius Config Reset: `setup/rad/clear-rad-config.sh`
> - Kubernetes Context setzen: `kubectl config use-context kind-kind`

## Demo 1 - Todolist

- In Ordner `apps/demo1-todolist` wechseln
- `rad init` ausführen
- ***Output erklären***
- `apps/demo1-todolist/app.bicep` inspizieren
- `apps/demo1-todolist/bicepconfig.json` inspizieren
- Bereitstellen:

    ```bash
    rad run app.bicep --application demo1-todolist
    ```

- ***`rad run` erklären***
- Application öffnen: http://localhost:7007
    - App zeigen
    - Todolist zeigen --> **Wichtige Info: Keine DB angebunden**
- Radius Dashboard öffnen: http://localhost:7007 (Basiert auf [Backstage](https://backstage.io))
    - Radius Dashboard durchgehen
    - App Graph zeigen
- Kubernetes Cluster zeigen
    - Namespaces zeigen: `kubectl get ns`
        - Radius Control Plane: `radius-system`
        - App: `default-demo1-todolist`
    - Ressourcen der App zeigen
        - Pods und Services: `kubectl get pod,svc`

> Info: Zum Löschen `rad application delete demo1-todolist` ausführen

## Demo 2 - Todolist mit DB

- In Ordner `apps/demo2-todolist-db` wechseln
- `rad init` ausführen
- Recipes auflisten, um zu sehen welche Datenbanken es gibt

    ```
    rad recipe list
    ```

- Wir brauchen das [`Applications.Datastores/redisCaches`](https://github.com/radius-project/recipes/blob/main/local-dev/rediscaches.bicep) Recipe
- `apps/demo2-todolist-db/app.bicep`
    1. `environment` Parameter hinzufügen

        ```
        @description('The Radius Environment ID. Injected automatically by the rad CLI.')
        param environment string
        ```
    
    2. Container Config anpassen: `name` ändern und `environment` einfügen

        ```
        name: 'demo2'
        properties: {
          ...
          environment: environment
          ...
        }
        ```
    
    3. Redis DB hinzugügen

        > Zeige weitere `Properties`. Diese sind für das Demo Setup nicht nötig

        ```
        resource redis 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
          name: 'redis'
          properties: {
            environment: environment
            application: application
          }
        }
        ```

        **Erklärung:**  
        Erstellt basierend des *Resource Types* und *Environments* einen Redis Cache.
    
    4. Connection zu Container hinzufügen

        ```
        resource demo 'Applications.Core/containers@2023-10-01-preview' = {
          name: 'demo2'
          ...
          properties: {
            ...
            connections: {
              redis: {
                source: redis.id
              }
            }
          }
        }
        ```

- Bereitstellen:

    ```bash
    rad run app.bicep --application demo2-todolist-db
    ```

- Connections erklären
- Todolist jetzt mit Redis Backing
- Radius Dashboard öffnen (http://localhost:7007) und Graph zeigen

## Demo 3 - AKS

> AKS hat mehr Performance. Deshalb können wir darauf etwas rumspielen

> Login zu Kubernetes Cluster vorher nötig. Nutze Azure Portal für Connection Info.

> Im App Ordner sind mehrere Beispiel für verschiedene Stufen.

- Kubernetes Context wechseln:
    - `kubectl config get-contexts`
    - `kubectl config use-context <name>`
- In Ordner `apps/demo3-aks` wechseln
- `rad init` ausführen
- **`apps/demo3-aks/app.bicep` inspizieren und erklären**
    - Scaling gesetzt auf 3 Replicas
    - Redis als Datenbank gesetzt
    - Gateway konfiguriert --> *Radius benutzt **Envoy** als Ingress*
- Deployment mit `rad deploy` --> Port-forwarding brauchen wir nicht

    ```
    rad deploy app.bicep --application demo3-aks
    ```

> App Uninstall: `rad application delete demo3-aks` 
> Radius wieder komplett löschen: `rad uninstall kubernetes --purge`


## Demo 4 - Beer Rating Local

- Kubernetes Context wechseln:
    - `kubectl config get-contexts`
    - `kubectl config use-context kind-kind`
- In Ordner `apps/demo4-beer-rating` wechseln
- `rad init` ausführen
- **`apps/demo4-beer-rating-local/app.bicep` inspizieren und erklären**
    - Radius Environment-Name und Application-Name
    - Datenbank SQL mit `Applications.Datastores/sqlDatabases`
    - Container
        - Backend
        - Frontend
        - Console Qutotes
    - Gateway

- Bereitstellen:

    ```bash
    rad run app.bicep --application demo4-beer-rating-local
    ```

- App Zugriff über FQDN: http://demo4-gateway.beerrating.radius.local
    - App testen
- Radius Dashboard öffnen (http://localhost:7007) und Graph zeigen

## Demo 5 - Beer Rating mit Azure SQL

> Lokale Umgebung, aber mit SQL in Azure.

> Benötigt Azure Service Principal mit Owner auf Resource Group.

- In Ordner `apps/demo5-beer-rating-azure-sql` wechseln
- **`rad init --full`** ausführen
    - Kubeconfig: kind-kind
    - Environment: azure
    - Namespace: azure
    - Add Cloud provider: yes
    - Cloud provider: Azure
    - Subscription auswählen
    - New Azure resource group: 'No', wenn bereits angelegt. Ansonsten 'Yes'.
    - Azure resource group erstellen oder auswählen
    - Azure Credential: Service Principal - der Einfachheit halber
    - Service Principal Infos angeben
    - Additional cloud providers: no
    - Setup in current Dir: yes
    - Prüfen und bestätigen
- Recipes auflisten, um zu, dass es keine Rezepte gibt

    ```
    rad recipe list
    ```

- Azure SQL Recipe bereitstellen

    > Das Recipe ist [recipes/azure/sqldatabase.bicep](recipes/azure/sqldatabase.bicep)  
    > und wurde in Container Registry bereitgestellt (siehe [Radius Recipes](README.md#radius-recipes))


    ```
    rad recipe register default \
      --environment azure \
      --group azure \
      --template-kind bicep \
      --template-path "acrcnrhiqgue-hkevf9ergae4bfbv.azurecr.io/radius-recipes/sqldatabase:0.60.2" \
      --resource-type "Applications.Datastores/sqlDatabases" \
      --parameters skuName=Basic \
      --parameters skuTier=Basic \
      --parameters backupStorageRedundancy=Local
    ```

- **`apps/demo5-beer-rating-azure-sql/app.bicep` inspizieren und erklären** --> gleich wie `apps/demo4-beer-rating-local/app.bicep`
    - Radius Environment-Name und Application-Name
    - Datenbank SQL mit `Applications.Datastores/sqlDatabases`
    - Container
        - Backend
        - Frontend
        - Console Qutotes
    - Gateway
- Bereitstellen:

    ```bash
    rad deploy app.bicep --application demo5-beer-rating-azure-sql --environment azure --group azure
    ```

- Graph Ressourcen anzeigen und Azure Ressourcen sehen:

    ```bash
    rad application graph --application demo5-beer-rating-azure-sql
    ```

- App Zugriff über FQDN: http://demo5-gateway.beerrating.radius.local
    - App testen
- Azure SQL zeigen
    - Tag hervorheben --> Im Rezept steht, dass diese Tags erstellt werden sollen

## Clean up

- Kind Cluster Reset: `setup/kind/reset/kind.sh`
- Radius Config Reset: `setup/rad/clear-rad-config.sh
- Azure Resourcen löschen: `az group rg-cloud-native-radius`
