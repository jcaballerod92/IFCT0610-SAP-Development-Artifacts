package es.jorge.sap.ifct0610.logic;

/**
 * @author Jorge Caballero Diaz
 * @version 1.0
 * @since 2024-04-10
 * * Proyecto: Certificado de Profesionalidad IFCT0610
 * Módulo: Programación en Sistemas de Planificación de Recursos (SAP)
 * Entorno de desarrollo: Visual Studio Code (Cloud/Desktop)
 * Módulo de validación para el Sistema de Gestión de Procesos (ERP-SAP Module)
 * Objetivo: Verificar la capacidad legal del sujeto según la normativa vigente.
 */
public class LegalAgeValidator
{

    // Constante de negocio: Definida por normativa legal
    private static final int MINIMUM_LEGAL_AGE = 18;

    public static void main(String[] args)
    {
        // Simulación de entrada de datos del sistema (Sujeto de prueba)
        int subjectAge = 20; 
        String subjectName = "Juan Pérez";

        System.out.println("--- Iniciando Validación de Elegibilidad ---");

        // Lógica de validación mediante estructura condicional
        if (subjectAge >= MINIMUM_LEGAL_AGE)
        {
            System.out.println("RESULTADO: El sujeto [" + subjectName + "] cumple los requisitos para participar.");
            // Aquí iría la lógica de registro en la base de datos de SAP
        }
        else
        {
            int yearsToWait = MINIMUM_LEGAL_AGE - subjectAge;
            System.out.println("RESULTADO: Acceso denegado. Sujeto no elegible por edad.");
            System.out.println("OBSERVACIÓN: Faltan " + yearsToWait + " años para cumplir el requisito.");
        }

        System.out.println("--- Proceso Finalizado con Éxito ---");
    }
}
