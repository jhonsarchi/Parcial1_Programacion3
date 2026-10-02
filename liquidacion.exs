defmodule Liquidacion do
  @moduledoc """
  Este módulo contiene los cálculos necesarios para obtener el pago semanal de cada
  recolector a partir de los pesajes que ya fueron validados.
  - autor_1: Daniel Yizack Gutiérrez Ruíz
  - autor_2: Jhon Fredy Sarchi Vélez
  - fecha: Octubre 2026
  """

  @tarifa_base 1000
  @kilos_bonificacion 120
  @bonificacion_diaria 8000
  @descuento_alimentacion 12000

  @doc """
  Función que calcula el valor de un pesaje válido,
  primero obtiene el valor base multiplicando los kilos por la tarifa y
  después aplica el ajuste correspondiente al porcentaje de granos verdes.
  """
  def valor_pesaje(pesaje) do
    valor_base = pesaje.kilos * @tarifa_base

    cond do
      pesaje.verdes <= 2 -> valor_base * 1.05
      pesaje.verdes <= 5 -> valor_base
      pesaje.verdes <= 10 -> valor_base * 0.90
      true -> valor_base * 0.70
    end
  end

  @doc """
  Esta función calcula la bonificación de un recolector para un día específico,
  la bonificación se entrega cuando la suma de kilos válidos de ese día
  alcanza o supera el valor definido para productividad.
  """
  def bonificacion_dia(pesajes_recolector, dia) do
    kilos_dia =
      pesajes_recolector
      |> Enum.filter(fn pesaje -> pesaje.dia == dia end)
      |> Enum.reduce(0, fn pesaje, total -> total + pesaje.kilos end)

    cond do
      kilos_dia >= @kilos_bonificacion -> @bonificacion_diaria
      true -> 0
    end
  end

  @doc """
  Función que calcula el descuento de alimentación usando la cantidad de días trabajados,
  solo se genera descuento cuando el recolector tiene activada la alimentación.
  """
  def descuento_alimentacion(recolector, dias_trabajados) do
    case recolector.alimentacion do
      true -> dias_trabajados * @descuento_alimentacion
      false -> 0
    end
  end

  @doc """
  Función que genera la liquidación de todos los recolectores,
  cada recolector produce un mapa con sus kilos, suma de pesajes,
  bonificaciones, alimentación, neto y cantidad de días trabajados.
  """
  def liquidar_recolectores(recolectores, pesajes_validos) do
    Enum.map(recolectores, fn recolector ->
      liquidar_recolector(recolector, pesajes_validos)
    end)
  end

  @doc """
  Esta función construye el detalle diario de un recolector,
  solo devuelve los días en los que existen pesajes válidos e incluye kilos,
  valor de los pesajes y bonificación de cada día.
  """
  def detalle_dias(codigo, pesajes_validos) do
    pesajes_recolector =
      Enum.filter(pesajes_validos, fn pesaje -> pesaje.recolector == codigo end)

    pesajes_recolector
    |> Enum.map(fn pesaje -> pesaje.dia end)
    |> Enum.uniq()
    |> Enum.sort_by(fn dia -> dia end, :asc)
    |> Enum.map(fn dia ->
      pesajes_dia = Enum.filter(pesajes_recolector, fn pesaje -> pesaje.dia == dia end)
      kilos = Enum.reduce(pesajes_dia, 0, fn pesaje, total -> total + pesaje.kilos end)
      valor = Enum.reduce(pesajes_dia, 0, fn pesaje, total -> total + valor_pesaje(pesaje) end)
      bonificacion = bonificacion_dia(pesajes_recolector, dia)

      %{dia: dia, kilos: kilos, valor_pesajes: valor, bonificacion: bonificacion}
    end)
  end

  # Calcula todos los valores de un recolector usando únicamente sus pesajes válidos.
  defp liquidar_recolector(recolector, pesajes_validos) do
    pesajes_recolector =
      Enum.filter(pesajes_validos, fn pesaje -> pesaje.recolector == recolector.codigo end)

    kilos = Enum.reduce(pesajes_recolector, 0, fn pesaje, total -> total + pesaje.kilos end)

    bruto =
      Enum.reduce(pesajes_recolector, 0, fn pesaje, total ->
        total + valor_pesaje(pesaje)
      end)

    dias =
      pesajes_recolector
      |> Enum.map(fn pesaje -> pesaje.dia end)
      |> Enum.uniq()

    bonificaciones =
      Enum.reduce(dias, 0, fn dia, total ->
        total + bonificacion_dia(pesajes_recolector, dia)
      end)

    alimentacion = descuento_alimentacion(recolector, length(dias))
    neto = bruto + bonificaciones - alimentacion

    %{
      codigo: recolector.codigo,
      nombre: recolector.nombre,
      kilos: kilos,
      bruto: bruto,
      bonificaciones: bonificaciones,
      alimentacion: alimentacion,
      neto: neto,
      dias_trabajados: length(dias)
    }
  end
end
