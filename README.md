# bomlo-bigquery-terraform
Terraform scipts for å opprette BigQuery-ressurser for Bømlo-klyngen

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
8. Lag VPC (f.eks. tbd_datastream_private_vpc)
9. Lag IP-range (f.eks. tbd_datastream_vpc_ip_range)
10. Gi databasen en private IP (NB: Da får databasen nedetid 😱) (f.eks. dataprodukt-arbeidsgiveropplysninger): 
    * Gå til databasen i GCP 
    * Trykk _Edit_ 
    * Trykk på _Connections_ 
    * Huk av for _Private IP_ 
    * Velg nettverket du lagde i punkt 8.
    * Trykk _Set up connection_
    * Trykk _Enable API_ (kun første gang per prosjekt)
    * Velg IP-range du lagde i punkt 9.
    * Trykk på _Create Connection_ 

11. Lag reverse proxy
12. Lag db connection profiles (inkl. secrets), datastream private connection 
13. Lag datastream_bigquery connection profile og dataset
14. Lag datastream
