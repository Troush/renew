defmodule Renew.Generator do
  import Mix.Generator

  def add_config(assigns, add) when is_binary(add) do
    {_, assigns} = Map.get_and_update(assigns, :config, fn config ->
      {config, config <> "\n" <> add}
    end)

    assigns
  end

  def add_test_config(assigns, add) when is_binary(add) do
    {_, assigns} = Map.get_and_update(assigns, :config_test, fn config_test ->
      {config_test, config_test <> "\n" <> add}
    end)

    assigns
  end

  def add_dev_config(assigns, add) when is_binary(add) do
    {_, assigns} = Map.get_and_update(assigns, :config_dev, fn config_dev ->
      {config_dev, config_dev <> "\n" <> add}
    end)

    assigns
  end

  def add_prod_config(assigns, add) when is_binary(add) do
    {_, assigns} = Map.get_and_update(assigns, :config_prod, fn config_prod ->
      {config_prod, config_prod <> "\n" <> add}
    end)

    assigns
  end

  def add_project_dependencies(assigns, add) when is_list(add) do
    {_, assigns} = Map.get_and_update(assigns, :project_dependencies, fn project_dependencies ->
      {project_dependencies, project_dependencies ++ add}
    end)

    assigns
  end

  def add_project_settings(assigns, add) when is_list(add) do
    {_, assigns} = Map.get_and_update(assigns, :project_settings, fn project_settings ->
      {project_settings, project_settings ++ add}
    end)

    assigns
  end

  def add_project_compilers(assigns, add) when is_list(add) do
    {_, assigns} = Map.get_and_update(assigns, :project_compilers, fn project_compilers ->
      {project_compilers, project_compilers ++ add}
    end)

    assigns
  end

  def add_project_applications(assigns, add) when is_list(add) do
    {_, assigns} = Map.get_and_update(assigns, :project_applications, fn project_applications ->
      {project_applications, project_applications ++ add}
    end)

    assigns
  end

  def set_project_start_module(assigns, {module, params}) when is_binary(module) and is_binary(params) do
    {_, assigns} = Map.get_and_update(assigns, :project_start_module, fn project_start_module ->
      {project_start_module, ",\n     mod: {#{module}, #{params}}"}
    end)

    assigns
  end

  def get_template(file, assigns) when is_list(assigns) do
    root = Path.expand("../templates", __DIR__)

    file
    |> (&Path.join(root, &1)).()
    |> File.read!
    |> EEx.eval_string(assigns: assigns)
  end

  def get_template(file, %{} = assigns) do
    assigns_map = assigns
    |> assigns_to_eex_map

    get_template(file, assigns_map)
  end

  def apply_template(files, path, assigns, opts \\ []) do
    # Convert everything to EEx strings
    assigns_map = assigns
    |> assigns_to_eex_map

    # Apply all templates
    for {format, source, destination} <- files do
      target = destination
      |> EEx.eval_string(assigns: assigns_map)
      |> (&Path.join(path, &1)).()

      case format do
        :cp ->
          template = source
          |> get_template(assigns_map)

          create_file(target, template, opts)
        :append ->
          template = source
          |> get_template(assigns_map)

          File.write!(target, File.read!(target) <> "\n" <> template)
        :mkdir ->
          File.mkdir_p!(target)
      end

      # Make shell scripts executable
      case Path.extname(target) do
        ".sh" ->
          System.cmd "chmod", ["+x", target]
        _ ->
          :ok
      end
    end
  end

  def assigns_to_eex_map(assigns) do
    assigns
    |> convert_project_dependencies
    |> convert_project_settings
    |> convert_project_applications
    |> convert_project_compilers
    |> Map.to_list
  end

  defp convert_project_dependencies(assigns) do
    {_, assigns} = Map.get_and_update(assigns, :project_dependencies, fn project_dependencies ->
      {project_dependencies, Enum.join(project_dependencies, ",\n     ")}
    end)

    assigns
  end

  defp convert_project_settings(assigns) do
    {_, assigns} = Map.get_and_update(assigns, :project_settings, fn project_settings ->
      t = Enum.join(project_settings, ",\n     ")
      case t do
        "" ->
          {project_settings, ""}
        _ ->
          {project_settings, ",\n     " <> t}
      end
    end)

    assigns
  end

  defp convert_project_applications(assigns) do
    {_, assigns} = Map.get_and_update(assigns, :project_applications, fn project_applications ->
      case project_applications do
        [] ->
          {project_applications, ""}
        _ ->
          {project_applications, ", " <> Enum.join(project_applications, ", ")}
      end
    end)

    assigns
  end

  defp convert_project_compilers(assigns) do
    {_, assigns} = Map.get_and_update(assigns, :project_compilers, fn project_compilers ->
      {project_compilers, Enum.join(project_compilers, ", ")}
    end)

    assigns
  end
end
