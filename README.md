# bomlo-bigquery-terraform
Terraform-scipts for å opprette BigQuery-ressurser for Bømloklyngen

## Hvordan kjøre Terraform lokalt

Dersom terraform allerede er satt opp og initiert for repo slik at bygg på GA fungerer, og du kun ønsker å inspisere hva terraform finner og rapporterer av endringer:

Følg oppskriften under fra og med pkt. 4 (Installer Terraform lokalt).

## Hvordan sette opp repo med Terraform første gang
Opprettelse av bucket og bruk av denne for terraform state må gjøres i to separate steg. Dette må gjøres lokalt fordi uten terraform state i bucketen så vil ikke GitHub Actions ha mulighet til å ta vare på state mellom kjøringer. Hvis vi prøver å gjøre dette via GitHub Actions vil bruk av bucket for terraform state feile da den i tillegg vil forsøke å opprette bucketen på nytt, fordi staten ikke har spor av opprettelsen av bucketen.
1. Opprett service account i GCP med permissions:
   * BigQuery Data Owner
   * Editor
   * Secret Manager Secret Accessor

   I dette repoet er det opprettet en bruker med navn `terraform` i `tbd-dev` og `tbd-prod` med disse tilgangene.

2. Opprett key for service account for hhv [dev](https://console.cloud.google.com/iam-admin/serviceaccounts?project=tbd-dev-7ff9) og [prod](https://console.cloud.google.com/iam-admin/serviceaccounts?project=tbd-prod-eacd)

   * Velg "Manage keys" fra actions for terraform-kontoen
   * Velg "Add keys" -> "Create new key" -> "Key type=JSON" -> "Create"
   * Key lagres til fil lokalt
   * Flytt filene til hjemmeområde og endre rettigheter slik: chmod go-rwx ~/tbd-terraform-*.key

3. Legg inn filen med service account keyen i [GitHub secret](https://github.com/navikt/bomlo-bigquery-terraform/settings/secrets/actions) (våre secrets heter GCP_SECRET_DEV og GCP_SECRET_PROD)

4. Installer Terraform lokalt
 
   F.eks med brew: brew install terraform

5. Gå til mappe du skal kjøre terraform fra (prod eller dev)

   Sett context (dev-gcp/prod-gcp) og kjør kommando: gcloud auth application-default login

6. Kjør kode lokalt for å opprette bucket (men ikke prøv å bruke den enda). Se kode i [commit](https://github.com/navikt/bomlo-bigquery-terraform/commit/3a6b7edb78a29052cd1e1dfae54c5ac3404768f8)
    ```
    terraform init
    terraform plan -refresh-only -detailed-exitcode
    ``` 
7. Når du er fornøyd med endringene terraform rapporterer om i punktet over, kjør følgende kommando: 
    ```
    terraform apply
    ```  
8. Kjør kode lokalt for å bruke bucket for state. Se kode i [commit](https://github.com/navikt/bomlo-bigquery-terraform/commit/42b61393184652e12f2efaf9bb974e7c7cfbeefb)
     ```
    terraform init
    ```   
9. Endre context til miljø det ikke er kjørt for å gjenta nødvendige steg over.
10. Nå kan workflowen pushes


## Hvordan sette opp en datastream i GCP med terraform

Legg merke til bruken av denne svært interessante emojien👇

🥇: betyr at dette steget kan gjenbrukes for flere datastreams og er allerede på plass for `tbd-dev` og `tbd-prod`. Dvs. er du en bømlis så kan du mest sannynlig hoppe over dette steget!


### Forutsetninger
Databasen man ønsker å streame til Bigquery må være klargjort. Dette innebærer:
1. Enable logical decoding, se [her](https://github.com/navikt/helse-dataprodukter/blob/5041c1cfd9fb85fb48ea0de2e3ac3882b4e3d0b6/arbeidsgiveropplysninger/deploy/nais.yml#L37)
2. Lag en databasebruker, se [her](https://github.com/navikt/helse-dataprodukter/blob/5041c1cfd9fb85fb48ea0de2e3ac3882b4e3d0b6/arbeidsgiveropplysninger/deploy/nais.yml#L35)
3. Gi den nye brukeren og den generelle databasebrukeren riktige tilganger, se [migrering V3](https://github.com/navikt/helse-dataprodukter/blob/main/forstegangsbehandling/src/main/resources/db/migration/V3__datastream_grants.sql)
   * NB: burde gjøres i en commit etter punktet over for å unngå race condition
4. Opprett publication og replication slots, se [migrering V4](https://github.com/navikt/helse-dataprodukter/blob/main/forstegangsbehandling/src/main/resources/db/migration/V4__datastream_publication.sql)
   og [V5](https://github.com/navikt/helse-dataprodukter/blob/main/forstegangsbehandling/src/main/resources/db/migration/V5__datastream_replication.sql)

Hvis du får problemer med å kjøre testene så trengs det muligens noen endringer i testconfigen. Prøv å legge til
`"-c", "wal_level=logical"` i PostgreSQLContaineren, se [her](https://github.com/navikt/helse-dataprodukter/blob/3e4245321e3ba5bf8e221b7e7ee8581d864c9d27/arbeidsgiveropplysninger/src/test/kotlin/arbeidsgiveropplysninger/TestDatabase.kt#L18)


### Steg for å sette opp datastream

1. 🥇 Lag en VPC (Virtual Private Cloud) (f.eks. `tbd_datastream_private_vpc`)
2. 🥇 Lag en IP-range (f.eks. `tbd_datastream_vpc_ip_range`)
3. Gi databasen en private IP manuelt i GCP. NB. databasen får nedetid i dette steget 😱 (f.eks. `dataprodukt-arbeidsgiveropplysninger`)
   1. Gå til databasen i GCP
   2. Trykk _Edit_
   3. Trykk på _Connections_
   4. Huk av for _Private IP_
   5. Velg VPC-en du lagde i punkt 1.
   6. Trykk _Set up connection_ (kun første gang per prosjekt)
   7. Trykk _Enable API_ (kun første gang per prosjekt)
   8. Velg IP-range du lagde i punkt 2. (kun første gang per prosjekt)
   9. Trykk på _Create Connection_
   10. Trykk på _Save_

4. 🥇 Lag datastream private connection med vpc peering med subnet (f.eks. `tbd_datastream_private_connection`)
5. Oppsett av firewallregler og reverse proxy, gjør en av følgende punkter:
   * Hvis du har satt opp dette fra før må du legge til:
      1. Den nye databasen som proxy instance, se [her](https://github.com/navikt/bomlo-bigquery-terraform/commit/08af6cda5adfc8ee07e0d13c7a61bcfa7cdcea0f) (se bort fra det ekstra mellomrommet som snek seg inn (og ble fjernet i neste commit))
      2. Ny firewall-regel som tillater connections fra databaseporten, se [her](https://github.com/navikt/bomlo-bigquery-terraform/blob/1349486438d25d890ef5a6a2a8603e1511db5377/prod/datastream-vpc.tf#L41)
   * 🥇 Hvis du ikke har satt opp firewall regler eller laget reverse proxy må dette gjøres slik som [her](https://github.com/navikt/bomlo-bigquery-terraform/commit/08f5d25cd1956cd686874247b51608031c979f85)

   Etter å ha gjort dette må du resette proxyen, se [Stuck](#stuck)

6. Lag en secret i Secret Manager manuelt i GCP for brukeren du opprettet i [Forutsetninger](#Forutsetninger):
   1. Hent ut brukerens passord og brukernavn fra secrets i kubernetes, dette opprettet nais automatisk da brukeren ble opprettet i `nais.yml`:
   ```
   brew install jq
   kubectl -n tbd get secret <navnet på secret> -o json | jq ".data | map_values(@base64d)"
   ```

   💡 Usikker på hva secreten din heter? Du kan liste opp secrets ved å kjøre kommandoen under og begynne å lete 🔎 Ofte starter secreten med `google`, har appnavnet i seg og slutter med en hash.
    ```
    kubectl -n tbd get secrets | grep <app-navn>
    ```
   2. Gå til Secret Manager i GCP, opprett secret, skriv følgende json:
   ```
   {
        "username": "<brukernavn fra secret>",
        "password": "<passord fra secret>"
   }
   ```
   3. Lagre
7. Opprett to connection profiles, se [commit](https://github.com/navikt/bomlo-bigquery-terraform/commit/6af1542dce45ac541a670e1f07bcd3a25e98f13d):
   1. mellom database og datastream (endringene i `datastream-dataprodukt-arbeidsgiveropplysninger.tf` og `secrets.tf` i commiten)
   2. 🥇 mellom datastream og bigquery (endringene i `datastream-vpc.tf` i commiten)
8. Lag datastream (f.eks. `arbeidsgiveropplysninger_datastream`)


### Stuck
* Når du legger til nye proxy instances så er det behov for å resette VM-en (den finner du på GCP: Compute Engine ➡️ VM instances ➡️ trykk på din VM ➡️ trykk på reset)
