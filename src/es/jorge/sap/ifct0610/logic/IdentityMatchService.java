package es.jorge.sap.ifct0610.logic;

import java.util.Objects;

/**
 * @author Jorge Caballero Diaz
 * @version 1.0
 * @since 2026-04-16
 * * Proyecto: Certificado de Profesionalidad IFCT0610
 * Módulo: Validación de Integridad de Datos (SAP Integration)
 * * Descripción: Módulo de comparación de identidades utilizando lógica condicional 
 * ternaria (inline if) y el método robusto de igualdad de objetos.
 */
public class IdentityMatchService
{

    public static void main(String[] args)
    {
       System.out.println("-------------------------------------------------");
       System.out.println("--- Iniciando Verificación de Identidad de Sistemas ---");
       System.out.println("-------------------------------------------------");

        // Simulación de credenciales o identificadores de sistema
        String sourceSystemId = "SAP_SERVER_PROD";
        String targetSystemId = "SAP_SERVER_PROD";
        System.out.println("\n--- Variables recogidas ---");
        System.out.println("-------------------------------------------------");
        System.out.println("ID Origen:   " + sourceSystemId);
        System.out.println("ID Destino:  " + targetSystemId);

        /**
         * Lógica de Negocio:
         * Usamos el operador ternario para una asignación limpia y profesional.
         * Nota Técnica: Se utiliza .equals() ya que en Java comparar Strings con '==' 
         * compara la dirección de memoria, no el contenido.
         */
        String validationResult = (Objects.equals(sourceSystemId, targetSystemId)) 
                ? "COINCIDENCIA EXITOSA: Los sistemas están sincronizados." 
                : "ERROR DE INTEGRIDAD: Los identificadores no coinciden.";

        // Presentación de resultados con formato profesional
        System.out.println("\n--- Resultado comparaccion ---");
        System.out.println("-------------------------------------------------");
        System.out.println("ESTADO: " + validationResult);
        System.out.println("-------------------------------------------------");
    }
}
