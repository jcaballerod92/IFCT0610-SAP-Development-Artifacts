# Financial Batch Loader

Proyecto Java orientado a simular un proceso batch financiero con validación de ficheros, carga de datos y persistencia en H2.

## Objetivo funcional
- Leer un fichero CSV de movimientos financieros.
- Validar formato y reglas de negocio.
- Insertar registros válidos en base de datos.
- Registrar errores de validación y errores técnicos.
- Generar un resultado final del lote.

## Tecnologías
- Java 8 compatible
- Maven
- JDBC
- H2 Database

## Estructura mínima
- `sample-files/financial_movements.csv`
- `src/main/java/...`
- `src/main/resources/schema.sql`
- `src/main/resources/application.properties`

## Ejecución
### Desde VSCode
1. Abre la carpeta del proyecto.
2. Asegúrate de tener instalado el Java Extension Pack.
3. Ejecuta la clase principal `FinancialBatchLoaderApplication`.

### Desde terminal
```bash
mvn clean compile
mvn exec:java
