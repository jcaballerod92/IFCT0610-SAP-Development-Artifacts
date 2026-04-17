package es.jorge.sap.ifct0610.logic;

import java.util.Scanner;

/**
 * @author Jorge Caballero Diaz
 * @version 1.0
 * @since 2026-04-17
 * * Proyecto: Certificado de Profesionalidad IFCT0610
 * Módulo: Lógica de Evaluación de KPIs (SAP Business Logic)
 * Entorno de desarrollo: Visual Studio Code (Cloud/Desktop)
 * * Descripción: Evalúa la validez y el estado de un indicador de calidad (0-10).
 * Demuestra el uso de estructuras condicionales encadenadas y validación de rangos.
 */
public class QualityScoreEvaluator
{

    // Constantes de Negocio: Evitan los "números mágicos" en el código
    private static final byte MIN_VALID_SCORE = 0;
    private static final byte PASS_THRESHOLD = 5;
    private static final byte MAX_VALID_SCORE = 10;

    public static void main(String[] args)
    {
        System.out.println("-------------------------------------------------");
        System.out.println("--- Sistema de Evaluación de Control de Calidad ---");
        System.out.println("-------------------------------------------------");

        // Uso de try-with-resources para asegurar el cierre del flujo de entrada
        try (Scanner scanner = new Scanner(System.in))
        {

            System.out.println("\n--- Solicitud del KPI de rendimiento ---");
            System.out.print("Introduzca el KPI de rendimiento (rango " + MIN_VALID_SCORE + "-" + MAX_VALID_SCORE + "): ");

            // Validación: ¿Es un número lo que ha introducido el usuario?
            if (!scanner.hasNextByte())
            {
                System.err.println("CRITICAL ERROR: Entrada no válida. Se requiere un valor numérico (byte).");
                return;
            }

            byte qualityScore = scanner.nextByte();

            // Lógica de Clasificación (Estructura if-else if-else optimizada)
            System.out.println("\n--- Clasificacion del estado (Cumple o no cumpleo o fuera de rango)---");
            if (qualityScore >= PASS_THRESHOLD && qualityScore <= MAX_VALID_SCORE)
            {
                System.out.println("ESTADO: [COMPLIANT] - El proceso cumple los estándares mínimos.");
            } 
            else if (qualityScore >= MIN_VALID_SCORE && qualityScore < PASS_THRESHOLD)
            {
                System.out.println("ESTADO: [NON-COMPLIANT] - Revisión requerida. Bajo umbral de calidad.");
            } 
            else {
                // Captura cualquier valor fuera del rango 0-10
                System.out.println("ESTADO: [OUT_OF_RANGE] - El valor " + qualityScore + " no es un KPI válido.");
            }

            System.out.println("\n--- Auditoría Finalizada ---");
        }
    }
}
