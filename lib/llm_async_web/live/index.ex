defmodule LlmAsyncWeb.Index do
  use LlmAsyncWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      assign(socket, text: "実行ボタンを押してください")
      |> assign(btn: true)

    {:ok, socket}
  end

  def handle_event("start", _, socket) do
    pid = self()

    socket =
      assign(socket, btn: false)
      |> assign(text: "")
      |> assign_async(:ret, fn -> run(pid) end)

    {:noreply, socket}
  end

  def run(pid) do
    client = Ollama.init()

    {:ok, ret} =
      Ollama.completion(client,
        model: "gemma3:1b",
        prompt: "Elixirについておしえて"
      )

    ret =
      ret
      |> Map.get("response")

    Process.send(pid, {:end, ret}, [])
    {:ok, %{ret: :ok}}
  end

  def handle_info({:end, msg}, socket) do
    socket =
      assign(socket, btn: true)
      |> assign(text: msg)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />
    <div class="p-5">
      <button disabled={!@btn} class="btn" phx-click="start">実行</button>
      <p class="m-2">{@text}</p>
    </div>
    """
  end
end
