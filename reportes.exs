defmodule Reportes do
  @moduledoc """
  Este módulo construye la información de los reportes como cadenas de texto,
  no realiza operaciones de entrada o salida. Recibe datos,
  procesa las colecciones y devuelve los resultados para que otro módulo
  decida cuándo mostrarlos.
  - autor_1: Daniel Yizack Gutiérrez Ruíz
  - autor_2: Jhon Fredy Sarchi Vélez
  - fecha: Octubre 2026
  """

  @meta_diaria 400
  @dias_cosecha 6

  @doc """
  Función que construye el reporte de pesajes rechazados,
  muestra cada pesaje junto con su primer motivo de rechazo y después
  presenta la cantidad de rechazos encontrada para cada motivo.
  """
  def reporte_r1(rechazados) do
    motivos = [
      :recolector_desconocido,
      :lote_desconocido,
      :dia_invalido,
      :kilos_fuera_de_rango,
      :porcentaje_invalido
    ]

    detalle =
      Enum.reduce(rechazados, "", fn rechazo, texto ->
        pesaje = rechazo.pesaje

        texto <>
          "#{pesaje.recolector} | #{pesaje.lote} | día #{pesaje.dia} | #{pesaje.kilos} kg | " <>
          "#{pesaje.verdes} % -> #{rechazo.motivo}\n"
      end)

    conteo =
      Enum.reduce(motivos, "", fn motivo, texto ->
        cantidad = Enum.count(rechazados, fn rechazo -> rechazo.motivo == motivo end)
        texto <> "#{motivo}: #{cantidad}\n"
      end)

    "R1. Pesajes rechazados\n" <> detalle <> "Rechazos por motivo\n" <> conteo
  end

  @doc """
  Función que construye el reporte de kilos y rendimiento por lote.
  El rendimiento se obtiene dividiendo los kilos válidos del lote entre
  sus hectáreas. Los resultados se ordenan de mayor a menor rendimiento.
  """
  def reporte_r2(lotes, pesajes_validos) do
    resultados =
      lotes
      |> Enum.map(fn lote ->
        kilos =
          pesajes_validos
          |> Enum.filter(fn pesaje -> pesaje.lote == lote.id end)
          |> Enum.reduce(0, fn pesaje, total -> total + pesaje.kilos end)

        rendimiento = calcular_rendimiento(kilos, lote.hectareas)

        %{
          nombre: lote.nombre,
          kilos: kilos,
          hectareas: lote.hectareas,
          rendimiento: rendimiento
        }
      end)
      |> Enum.sort_by(fn resultado -> resultado.rendimiento end, :desc)

    cuerpo =
      Enum.reduce(resultados, "", fn resultado, texto ->
        texto <>
          "#{resultado.nombre} | #{resultado.kilos} kg | #{resultado.hectareas} ha | " <>
          "#{formatear_decimal(resultado.rendimiento)} kg/ha\n"
      end)

    "R2. Kilos por lote\n" <> cuerpo
  end

  @doc """
  Esta función devuelve un mapa con los kilos válidos de la finca para cada día del 1 al 6.
  La clave del mapa es el número del día y el valor corresponde a la suma
  de kilos válidos registrados en ese día.
  """
  def kilos_por_dia(pesajes_validos) do
    Enum.reduce(1..@dias_cosecha, %{}, fn dia, mapa ->
      kilos =
        pesajes_validos
        |> Enum.filter(fn pesaje -> pesaje.dia == dia end)
        |> Enum.reduce(0, fn pesaje, total -> total + pesaje.kilos end)

      Map.put(mapa, dia, kilos)
    end)
  end

  @doc """
  Esta función construye el reporte de producción diaria y cumplimiento de la meta,
  incluye los seis días, incluso cuando un día no tiene pesajes válidos,
  y al final informa si la meta se cumplió todos los días o al menos uno.
  """
  def reporte_r3(pesajes_validos) do
    mapa = kilos_por_dia(pesajes_validos)

    cuerpo =
      Enum.reduce(1..@dias_cosecha, "", fn dia, texto ->
        kilos = Map.get(mapa, dia)
        estado = estado_meta(kilos)
        texto <> "Día #{dia}: #{kilos} kg -> #{estado}\n"
      end)

    todos = Enum.all?(1..@dias_cosecha, fn dia -> Map.get(mapa, dia) >= @meta_diaria end)
    alguno = Enum.any?(1..@dias_cosecha, fn dia -> Map.get(mapa, dia) >= @meta_diaria end)

    "R3. Kilos por día (meta: #{@meta_diaria} kg)\n" <>
      cuerpo <>
      "¿Se cumplió la meta todos los días? #{si_no(todos)}\n" <>
      "¿Se cumplió la meta al menos un día? #{si_no(alguno)}\n"
  end

  @doc """
  Función que construye la liquidación semanal de todos los recolectores,
  ordena las liquidaciones de mayor a menor valor neto y las numera desde 1.
  Los valores monetarios se muestran con dos cifras decimales.
  """
  def reporte_r4(liquidaciones) do
    cuerpo =
      liquidaciones
      |> Enum.sort_by(fn liquidacion -> liquidacion.neto end, :desc)
      |> Enum.with_index()
      |> Enum.reduce("", fn {liquidacion, indice}, texto ->
        numero = indice + 1

        texto <>
          "#{numero}. | #{liquidacion.nombre} | #{liquidacion.kilos} kg | " <>
          "$#{formatear_decimal(liquidacion.bruto)} | " <>
          "$#{formatear_decimal(liquidacion.bonificaciones)} | " <>
          "$#{formatear_decimal(liquidacion.alimentacion)} | " <>
          "$#{formatear_decimal(liquidacion.neto)}\n"
      end)

    "R4. Liquidación de la semana\n" <>
      "# | Recolector | Kilos | Pesajes | Bonificaciones | Alimentación | Neto\n" <>
      cuerpo
  end

  @doc """
  Función que construye el reporte del mejor recolector de cada día.
  Cuando varios recolectores tienen el mismo máximo de kilos, conserva a
  todos los empatados. Al final cuenta quién apareció como mejor más días.
  """
  def reporte_r5(recolectores, pesajes_validos) do
    mejores_por_dia =
      Enum.map(1..@dias_cosecha, fn dia ->
        kilos_recolectores = kilos_recolectores_dia(recolectores, pesajes_validos, dia)
        mejores_del_dia(dia, kilos_recolectores)
      end)

    cuerpo =
      Enum.reduce(mejores_por_dia, "", fn resultado, texto ->
        texto <> texto_mejores_dia(resultado)
      end)

    final = texto_mas_dias_como_mejor(mejores_por_dia, recolectores)

    "R5. Mejor recolector de cada día\n" <> cuerpo <> final <> "\n"
  end

  @doc """
  Función que construye el reporte del recolector con mejor calidad.
  Solo considera recolectores con tres o más pesajes válidos y usa el
  porcentaje de verdes ponderado por kilos para comparar la calidad.
  """
  def reporte_r6(recolectores, pesajes_validos) do
    candidatos =
      recolectores
      |> Enum.map(fn recolector ->
        pesajes =
          Enum.filter(pesajes_validos, fn pesaje -> pesaje.recolector == recolector.codigo end)

        %{recolector: recolector, pesajes: pesajes}
      end)
      |> Enum.filter(fn candidato -> length(candidato.pesajes) >= 3 end)
      |> Enum.map(fn candidato ->
        suma_kilos =
          Enum.reduce(candidato.pesajes, 0, fn pesaje, total -> total + pesaje.kilos end)

        suma_ponderada =
          Enum.reduce(candidato.pesajes, 0, fn pesaje, total ->
            total + pesaje.verdes * pesaje.kilos
          end)

        %{
          nombre: candidato.recolector.nombre,
          porcentaje: suma_ponderada / suma_kilos
        }
      end)

    case candidatos do
      [] ->
        "R6. Mejor calidad (mínimo 3 pesajes válidos)\n" <>
          "No hay recolectores que cumplan el mínimo.\n"

      _ ->
        mejor = Enum.min_by(candidatos, fn candidato -> candidato.porcentaje end)

        "R6. Mejor calidad (mínimo 3 pesajes válidos)\n" <>
          "#{mejor.nombre}, con #{formatear_decimal(mejor.porcentaje)} % " <>
          "de verdes ponderado por kilos\n"
    end
  end

  @doc """
  Función que construye el total pagado por la finca y el costo promedio por kilo válido.
  """
  def reporte_r7(liquidaciones, pesajes_validos) do
    total =
      Enum.reduce(liquidaciones, 0, fn liquidacion, acumulado ->
        acumulado + liquidacion.neto
      end)

    kilos =
      Enum.reduce(pesajes_validos, 0, fn pesaje, acumulado ->
        acumulado + pesaje.kilos
      end)

    promedio = costo_promedio(total, kilos)

    "R7. Totales de la semana\n" <>
      "Total a pagar: $#{formatear_decimal(total)}\n" <>
      "Kilos válidos: #{kilos} kg\n" <>
      "Costo promedio por kilo: $#{formatear_decimal(promedio)}\n"
  end

  @doc """
  Esta función construye la lista de recolectores que registraron pesajes válidos
  en todos los lotes disponibles.
  """
  def reporte_r8(recolectores, lotes, pesajes_validos) do
    ids_lotes = Enum.map(lotes, fn lote -> lote.id end)

    cumplen =
      Enum.filter(recolectores, fn recolector ->
        lotes_recolector =
          pesajes_validos
          |> Enum.filter(fn pesaje -> pesaje.recolector == recolector.codigo end)
          |> Enum.map(fn pesaje -> pesaje.lote end)
          |> Enum.uniq()

        Enum.all?(ids_lotes, fn id_lote -> id_lote in lotes_recolector end)
      end)

    cuerpo =
      case cumplen do
        [] ->
          "Ningún recolector trabajó en todos los lotes.\n"

        _ ->
          Enum.reduce(cumplen, "", fn recolector, texto ->
            texto <> recolector.nombre <> "\n"
          end)
      end

    "R8. Recolectores que trabajaron en todos los lotes\n" <> cuerpo
  end

  @doc """
  Esta función ordena y limita una lista de liquidaciones usando opciones recibidas
  en una keyword list, las opciones disponibles son :campo, :orden y :limite.
  """
  def ranking(liquidaciones, opciones) do
    campo = Keyword.get(opciones, :campo, :neto)
    orden = Keyword.get(opciones, :orden, :desc)
    limite = Keyword.get(opciones, :limite, length(liquidaciones))

    liquidaciones
    |> Enum.sort_by(fn liquidacion -> valor_campo(liquidacion, campo) end, orden)
    |> Enum.take(limite)
    |> Enum.with_index()
    |> Enum.reduce("", fn {liquidacion, indice}, texto ->
      numero = indice + 1

      texto <>
        "#{numero}. #{liquidacion.nombre} | #{campo}: " <>
        "#{formatear_valor_ranking(valor_campo(liquidacion, campo), campo)}\n"
    end)
  end

  @doc """
  Esta función combina dos mapas de producción diaria,
  cuando un día aparece en los dos mapas, suma sus kilos, los días que
  aparecen en un solo mapa conservan su valor original.
  """
  def combinar_fincas(finca, finca_vecina) do
    Map.merge(finca, finca_vecina, fn _dia, kilos_finca, kilos_vecina ->
      kilos_finca + kilos_vecina
    end)
  end

  @doc """
  Función que construye el desprendible de pago de un recolector,
  si el código no existe devuelve un mensaje informativo. Cuando existe,
  muestra el detalle de cada día trabajado y los totales de la liquidación.
  """
  def desprendible(codigo, recolectores, liquidaciones, pesajes_validos) do
    recolector = Enum.find(recolectores, fn dato -> dato.codigo == codigo end)

    case recolector do
      nil ->
        "No existe un recolector con el código #{codigo}."

      _ ->
        liquidacion = Enum.find(liquidaciones, fn dato -> dato.codigo == codigo end)
        detalle = Liquidacion.detalle_dias(codigo, pesajes_validos)

        dias =
          Enum.reduce(detalle, "", fn dia, texto ->
            texto <>
              "Día #{dia.dia}: #{dia.kilos} kg | " <>
              "pesajes $#{formatear_decimal(dia.valor_pesajes)} | " <>
              "bonificación $#{formatear_decimal(dia.bonificacion)}\n"
          end)

        "Desprendible de pago - #{recolector.nombre} (#{recolector.codigo})\n" <>
          dias <>
          "Suma de pesajes: $#{formatear_decimal(liquidacion.bruto)}\n" <>
          "Bonificaciones: $#{formatear_decimal(liquidacion.bonificaciones)}\n" <>
          "Alimentación (#{liquidacion.dias_trabajados} días): " <>
          "-$#{formatear_decimal(liquidacion.alimentacion)}\n" <>
          "Neto a pagar: $#{formatear_decimal(liquidacion.neto)}"
    end
  end

  # Calcula el rendimiento de un lote evitando una división entre cero.
  defp calcular_rendimiento(kilos, hectareas) do
    cond do
      hectareas > 0 -> kilos / hectareas
      true -> 0
    end
  end

  # Devuelve el texto que corresponde al cumplimiento de la meta diaria.
  defp estado_meta(kilos) do
    cond do
      kilos >= @meta_diaria -> "cumplió la meta"
      true -> "no cumplió la meta"
    end
  end

  # Calcula los kilos de cada recolector para un día y elimina los resultados en cero.
  defp kilos_recolectores_dia(recolectores, pesajes_validos, dia) do
    recolectores
    |> Enum.map(fn recolector ->
      kilos =
        pesajes_validos
        |> Enum.filter(fn pesaje ->
          pesaje.dia == dia and pesaje.recolector == recolector.codigo
        end)
        |> Enum.reduce(0, fn pesaje, total -> total + pesaje.kilos end)

      %{codigo: recolector.codigo, nombre: recolector.nombre, kilos: kilos}
    end)
    |> Enum.filter(fn resultado -> resultado.kilos > 0 end)
  end

  # Obtiene el máximo de kilos del día y conserva todos los recolectores empatados.
  defp mejores_del_dia(dia, kilos_recolectores) do
    case kilos_recolectores do
      [] ->
        %{dia: dia, kilos: 0, mejores: []}

      _ ->
        maximo = Enum.max_by(kilos_recolectores, fn resultado -> resultado.kilos end).kilos
        mejores = Enum.filter(kilos_recolectores, fn resultado -> resultado.kilos == maximo end)
        %{dia: dia, kilos: maximo, mejores: mejores}
    end
  end

  # Construye una línea del reporte diario del mejor recolector.
  defp texto_mejores_dia(resultado) do
    case resultado.mejores do
      [] ->
        "Día #{resultado.dia}: sin pesajes\n"

      mejores ->
        nombres =
          mejores
          |> Enum.map(fn mejor -> mejor.nombre end)
          |> Enum.join(", ")

        "Día #{resultado.dia}: #{nombres} (#{resultado.kilos} kg)\n"
    end
  end

  # Cuenta las apariciones como mejor diario y construye la línea final de R5.
  defp texto_mas_dias_como_mejor(mejores_por_dia, recolectores) do
    codigos =
      mejores_por_dia
      |> Enum.reduce([], fn resultado, lista -> lista ++ resultado.mejores end)
      |> Enum.map(fn mejor -> mejor.codigo end)

    case codigos do
      [] ->
        "No hubo pesajes válidos en la semana."

      _ ->
        conteos =
          codigos
          |> Enum.uniq()
          |> Enum.map(fn codigo ->
            cantidad = Enum.count(codigos, fn actual -> actual == codigo end)
            %{codigo: codigo, cantidad: cantidad}
          end)

        maximo = Enum.max_by(conteos, fn conteo -> conteo.cantidad end).cantidad

        codigos_mejores =
          conteos
          |> Enum.filter(fn conteo -> conteo.cantidad == maximo end)
          |> Enum.map(fn conteo -> conteo.codigo end)

        nombres =
          recolectores
          |> Enum.filter(fn recolector -> recolector.codigo in codigos_mejores end)
          |> Enum.map(fn recolector -> recolector.nombre end)
          |> Enum.join(", ")

        "Más días como mejor recolector: #{nombres} (#{maximo} días)"
    end
  end

  # Calcula el costo promedio y evita dividir cuando no existen kilos válidos.
  defp costo_promedio(total, kilos) do
    cond do
      kilos > 0 -> total / kilos
      true -> 0
    end
  end

  # Selecciona el valor de la liquidación que se utilizará para ordenar el ranking.
  defp valor_campo(liquidacion, :kilos), do: liquidacion.kilos
  defp valor_campo(liquidacion, :bruto), do: liquidacion.bruto
  defp valor_campo(liquidacion, _), do: liquidacion.neto

  # Presenta el campo del ranking en kilos o en pesos según corresponda.
  defp formatear_valor_ranking(valor, :kilos), do: "#{valor} kg"
  defp formatear_valor_ranking(valor, _), do: "$#{formatear_decimal(valor)}"

  # Convierte un número a texto con dos cifras decimales.
  defp formatear_decimal(numero) do
    :erlang.float_to_binary(numero * 1.0, decimals: 2)
  end

  # Convierte valores booleanos en palabras para los reportes.
  defp si_no(true), do: "Sí"
  defp si_no(false), do: "No"
end
