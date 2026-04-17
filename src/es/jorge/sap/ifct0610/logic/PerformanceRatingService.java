package es.jorge.sap.ifct0610.logic;

import java.util.Scanner;

/**
 * @author Jorge Caballero
 * @version 1.0
 * @since 2026-04-17
 * * Proyecto: Certificado de Profesionalidad IFCT0610
 * Módulo: Gestión de Estados y Calificaciones (ERP Logic)
 * Entorno de desarrollo: Visual Studio Code (Cloud/Desktop)
 * * Descripción: Módulo que traduce códigos numéricos de rendimiento en 
 * etiquetas descriptivas de estado de negocio mediante estructuras switch-case.
 */
public class PerformanceRatingService {

    public static void main(String[] args) {

       System.out.println("-------------------------------------------------");
       System.out.println("--- Módulo de Clasificación de Rendimiento Operativo ---");
       System.out.println("-------------------------------------------------");

       // Uso de try-with-resources para gestión automática del Scanner
        try (Scanner scanner = new Scanner(System.in)) {

            System.out.println("\n--- Solicitud de nivel de rendimiento ---");
            System.out.println("-------------------------------------------------");
            System.out.print("Introduzca el nivel de rendimiento detectado (0-10): ");

            // Validación de entrada para robustez del sistema
            if (!scanner.hasNextByte()) {
                System.err.println("ERROR CRÍTICO: El sistema espera un valor numérico de tipo byte.");
                return;
            }

            byte performanceLevel = scanner.nextByte();
            String statusDescription;

            // Selección de estado basada en el código de entrada
            System.out.println("\n--- Clasificacion del rendimiento ---");
            System.out.println("-------------------------------------------------");
            switch (performanceLevel) {
                case 0:
                case 1:
                    statusDescription = "CRÍTICO (Suspenso)";
                    break;
                case 2:
                    statusDescription = "MUY DEFICIENTE";
                    break;
                case 3:
                    statusDescription = "DEFICIENTE";
                    break;
                case 4:
                    statusDescription = "INSUFICIENTE - Requiere plan de mejora";
                    break;
                case 5:
                    statusDescription = "SUFICIENTE - Cumplimiento mínimo";
                    break;
                case 6:
                    statusDescription = "BIEN - Rendimiento estándar";
                    break;
                case 7:
                case 8:
                    statusDescription = "NOTABLE - Rendimiento optimizado";
                    break;
                case 9:
                    statusDescription = "SOBRESALIENTE - Excelencia operativa";
                    break;
                case 10:
                    statusDescription = "MATRÍCULA DE HONOR - Referente de sector";
                    break;
                default:
                    statusDescription = "CÓDIGO NO VÁLIDO (Fuera de rango)";
                    break;
            }

            // Salida de resultados con formato de reporte
            System.out.println("Nivel evaluado: " + performanceLevel);
            System.out.println("Diagnóstico:    " + statusDescription);
            System.out.println("-----------------------------------------");
        }
        
        System.out.println("Log de sistema: Transacción finalizada.");
    }
}
