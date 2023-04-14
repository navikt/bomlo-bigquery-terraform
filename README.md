# bomlo-bigquery-terraform
Terraform-scipts for å opprette BigQuery-ressurser for Bømloklyngen

## Hvordan komme i gang med Terraform
Opprettelse av bucket og bruk av denne for terraform state må gjøres i to separate steg. Dette må gjøres lokalt fordi uten terraform state i bucketen så vil ikke GitHub Actions ha mulighet til å ta vare på state mellom kjøringer. Hvis vi prøver å gjøre dette via GitHub Actions vil bruk av bucket for terraform state feile da den i tillegg vil forsøke å opprette bucketen på nytt, fordi staten ikke har spor av opprettelsen av bucketen.
1. Opprett service account i GCP med permissions:
   * BigQuery Data Owner
   * Editor
   * Secret Manager Secret Accessor
I dette repoet er det opprettet en bruker med navn `terraform` i `tbd-dev` og `tbd-prod` med disse tilgangene. 
   
2. Opprett key for service account og last ned
3. Legg inn filen med service account keyen i GitHub secret (våre secrets heter GCP_SECRET_DEV og GCP_SECRET_PROD)
4. Installer Terraform lokalt og sett miljøvariabel GOOGLE_APPLICATION_CREDENTIALS som peker til den nedlastede filen
    
    NB: Denne gir tilgang til service accounten i GCP, så den burde nok ikke beholdes lokalt, spesielt for prod
5. Kjør kode lokalt for å opprette bucket (men ikke prøv å bruke den enda). Se kode i [commit](https://github.com/navikt/bomlo-bigquery-terraform/commit/3a6b7edb78a29052cd1e1dfae54c5ac3404768f8) 
    ```
    terraform init
    terraform plan
    terraform apply
    ```    
6. Kjør kode lokalt for å bruke bucket for state. Se kode i [commit](https://github.com/navikt/bomlo-bigquery-terraform/commit/42b61393184652e12f2efaf9bb974e7c7cfbeefb)
     ```
    terraform init
    ```   
7. Nå kan workflowen pushes

## Hvordan sette opp en datastream i GCP med terraform

Legg merke til bruken av denne svært interessante emojien👇 

🥇: betyr at dette steget kan gjenbrukes for flere datastreams og er allerede på plass for `tbd-dev` og `tbd-prod`. Dvs. er du en bømlis så kan du mest sannynlig hoppe over dette steget!


### Forutsetninger 
Databasen man ønsker å streame til Bigquery må være klargjort. Dette innebærer:
1. lage en databasebruker, se [her](https://github.com/navikt/helse-dataprodukter/blob/5041c1cfd9fb85fb48ea0de2e3ac3882b4e3d0b6/arbeidsgiveropplysninger/deploy/nais.yml#L35)
2. gi den nye brukeren og den generelle databasebrukeren riktige tilganger, se [migrering V3](https://github.com/navikt/helse-dataprodukter/blob/main/arbeidsgiveropplysninger/src/main/resources/db/migration/V3__datastream_grants.sql) 
   * NB: burde gjøres i en commit etter punktet over for å unngå race condition
3. opprette publication og replication slots, se se [migrering V4](https://github.com/navikt/helse-dataprodukter/blob/main/arbeidsgiveropplysninger/src/main/resources/db/migration/V4__datastream_publication.sql)
og [V5](https://github.com/navikt/helse-dataprodukter/blob/main/arbeidsgiveropplysninger/src/main/resources/db/migration/V5__datastream_replication.sql) 


### Steg for å sette op datastream 

1. 🥇 Lag en VPC (Virtual Private Cloud) (f.eks. `tbd_datastream_private_vpc`)
2. 🥇 Lag en IP-range (f.eks. `tbd_datastream_vpc_ip_range`)
3. Gi databasen en private IP manuelt i GCP. NB. databasen får nedetid i dette steget 😱 (f.eks. `dataprodukt-arbeidsgiveropplysninger`) 
   1. Gå til databasen i GCP 
   2. Trykk _Edit_ 
   3. Trykk på _Connections_ 
   4. Huk av for _Private IP_ 
   5. Velg nettverket du lagde i punkt 8.
   6. Trykk _Set up connection_
   7. Trykk _Enable API_ (kun første gang per prosjekt)
   8. Velg IP-range du lagde i punkt 9.
   9. Trykk på _Create Connection_ 
   10. Trykk på _Save_ 

4. 🥇 Lag datastream private connection med vpc peering med subnet (f.eks. `tbd_datastream_private_connection`)
5. Oppsett av firewallregler og reverse proxy, gjør en av følgende punkter: 
   * Hvis du har satt opp dette fra før må du legge til: 
      1. Den nye databasen som proxy instance, se [her](https://github.com/navikt/bomlo-bigquery-terraform/blob/1349486438d25d890ef5a6a2a8603e1511db5377/prod/datastream-vpc.tf#L54)
      2. Ny firewall-regel som tillater connections fra databaseporten, se [her](https://github.com/navikt/bomlo-bigquery-terraform/blob/1349486438d25d890ef5a6a2a8603e1511db5377/prod/datastream-vpc.tf#L41)
   * 🥇 Hvis du ikke har satt opp firewall regler eller laget reverse proxy må dette gjøres slik som [her](https://github.com/navikt/bomlo-bigquery-terraform/commit/08f5d25cd1956cd686874247b51608031c979f85)
6. Lag en secret i Secret Manager manuelt i GCP for brukeren du opprettet i [Forutsetninger](#Forutsetninger):  
   1. Hent ut brukerens passord og brukernavn fra secrets i kubernetes, dette opprettet nais automatisk da brukeren ble opprettet i `nais.yml`:
   ```
   brew install jq
   kubectl -n tbd get secret <navnet på secret> -o json | jq ".data | map_values(@base64d)"
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
   1. mellom database og datastream 
   2. 🥇 mellom datastream og bigquery
8. Lag datastream (f.eks. `arbeidsgiveropplysninger_datastream`)


### Står fast? 
* Når du legger til nye proxy instances så er det behov for å resette VM-en (den finner du på GCP: Compute Engine ➡️ VM instances ➡️ trykk på din VM ➡️ trykk på reset ➡️ prøv å kjør bygget på nytt)
