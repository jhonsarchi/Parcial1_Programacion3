defmodule Programa do
  @moduledoc """
  Este módulo coordina la ejecución completa de la aplicación, carga los datos,
  solicita la entrada adicional, obtiene las liquidaciones,
  muestra los reportes y permite consultar un desprendible de pago.
  - autor_1: Daniel Yizack Gutiérrez Ruíz
  - autor_2: Jhon Fredy Sarchi Vélez
  - fecha: Octubre 2026
  """

  # Inicia el flujo principal de la aplicación.
  def main do
    recolectores = Datos.recolectores()
    lotes = Datos.lotes()
    pesajes = Datos.pesajes()

    {pesajes_validos_iniciales, rechazados_iniciales} =
      Validacion.separar_pesajes(pesajes, recolectores, lotes)

    {pesajes_validos, rechazados} =
      solicitar_pesaje_adicional(
        pesajes_validos_iniciales,
        rechazados_iniciales,
        recolectores,
        lotes
      )

    liquidaciones = Liquidacion.liquidar_recolectores(recolectores, pesajes_validos)

    mostrar_reportes(recolectores, lotes, pesajes_validos, rechazados, liquidaciones)
    mostrar_investigacion(pesajes_validos, liquidaciones)
    solicitar_desprendible(recolectores, pesajes_validos, liquidaciones)
  end


  # Solicita una sola línea de pesaje y decide si se omite, se rechaza o se agrega.
  defp solicitar_pesaje_adicional(pesajes_validos, rechazados, recolectores, lotes) do
    linea =
      Util.leer(
        "Ingrese un pesaje adicional (recolector;lote;dia;kilos;verdes) o Enter para omitir: ",
        :string
      )

    case linea do
      "" ->
        Util.imprimir_mensaje("No se agregó ningún pesaje.")
        {pesajes_validos, rechazados}

      _ ->
        procesar_pesaje_adicional(linea, pesajes_validos, rechazados, recolectores, lotes)
    end
  end

  # Convierte la línea escrita por el usuario y continúa con la validación del pesaje.
  defp procesar_pesaje_adicional(linea, pesajes_validos, rechazados, recolectores, lotes) do
    case Validacion.convertir_linea_pesaje(linea) do
      {:error, :formato_invalido} ->
        Util.imprimir_error("Pesaje rechazado: formato_invalido")
        {pesajes_validos, rechazados}

      {:ok, pesaje} ->
        agregar_pesaje_validado(pesaje, pesajes_validos, rechazados, recolectores, lotes)
    end
  end

  # Aplica las reglas de validación al pesaje adicional y actualiza las listas de trabajo.
  defp agregar_pesaje_validado(pesaje, pesajes_validos, rechazados, recolectores, lotes) do
    case Validacion.validar_pesaje(pesaje, recolectores, lotes) do
      {:ok, pesaje_valido} ->
        Util.imprimir_mensaje(
          "Pesaje agregado: #{pesaje_valido.recolector} en #{pesaje_valido.lote}, día #{pesaje_valido.dia}, " <>
            "#{pesaje_valido.kilos} kg, #{pesaje_valido.verdes} % de verdes."
        )

        {pesajes_validos ++ [pesaje_valido], rechazados}

      {:error, motivo} ->
        Util.imprimir_error("Pesaje rechazado: #{motivo}")
        rechazo = %{pesaje: pesaje, motivo: motivo}
        {pesajes_validos, rechazados ++ [rechazo]}
    end
  end

  # Obtiene los ocho reportes y los muestra en el mismo orden de procesamiento.
  defp mostrar_reportes(recolectores, lotes, pesajes_validos, rechazados, liquidaciones) do
    Util.imprimir_mensaje("\n" <> Reportes.reporte_r1(rechazados))
    Util.imprimir_mensaje(Reportes.reporte_r2(lotes, pesajes_validos))
    Util.imprimir_mensaje(Reportes.reporte_r3(pesajes_validos))
    Util.imprimir_mensaje(Reportes.reporte_r4(liquidaciones))
    Util.imprimir_mensaje(Reportes.reporte_r5(recolectores, pesajes_validos))
    Util.imprimir_mensaje(Reportes.reporte_r6(recolectores, pesajes_validos))
    Util.imprimir_mensaje(Reportes.reporte_r7(liquidaciones, pesajes_validos))
    Util.imprimir_mensaje(Reportes.reporte_r8(recolectores, lotes, pesajes_validos))
  end

  # Muestra las tres variantes del ranking y la combinación de producción diaria.
  defp mostrar_investigacion(pesajes_validos, liquidaciones) do
    Util.imprimir_mensaje("Ranking por defecto\n" <> Reportes.ranking(liquidaciones, []))

    Util.imprimir_mensaje(
      "Ranking por kilos, límite 3\n" <>
        Reportes.ranking(liquidaciones, campo: :kilos, limite: 3)
    )

    Util.imprimir_mensaje(
      "Ranking por bruto ascendente\n" <>
        Reportes.ranking(liquidaciones, orden: :asc, campo: :bruto)
    )

    finca = Reportes.kilos_por_dia(pesajes_validos)
    finca_vecina = %{1 => 520.5, 2 => 610, 3 => 480, 5 => 700, 7 => 300}
    combinado = Reportes.combinar_fincas(finca, finca_vecina)
    Util.imprimir_mensaje("Producción combinada de las dos fincas: #{inspect(combinado)}")
  end

  # Solicita un código y muestra el desprendible construido para ese recolector.
  defp solicitar_desprendible(recolectores, pesajes_validos, liquidaciones) do
    codigo = Util.leer("Ingrese el código del recolector para ver su desprendible: ", :string)

    Reportes.desprendible(codigo, recolectores, liquidaciones, pesajes_validos)
    |> Util.imprimir_mensaje()
  end
end

Programa.main()
