defmodule ExSemanticWeb.RoomChannel do
  @moduledoc false

  use Phoenix.Channel
  require Logger

  def join("room:lobby", message, socket) do
    Process.flag(:trap_exit, true)
    :timer.send_interval(1_000, :ping)
    send(self(), {:after_join, message})

    {:ok, socket}
  end

  def join("room:" <> _private_subtopic, _message, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info({:after_join, msg}, socket) do
    broadcast! socket, "user:entered", %{user: msg["user"]}
    push socket, "join", %{status: "connected"}
    {:noreply, socket}
  end

  def handle_info(:ping, socket) do
    push socket, "new:msg", %{user: "SYSTEM", body: "ping"}
    {:noreply, socket}
  end

  def terminate(reason, _socket) do
    Logger.debug "> leave #{inspect reason}"
    :ok
  end

  def handle_in("new:msg", msg, socket) do
    Logger.debug fn -> "HANDLE_IN msg: #{inspect msg, pretty: true}" end
    Logger.debug fn -> "HANDLE_IN sck: #{inspect socket, pretty: true}" end
    broadcast! socket, "new:msg", %{user: msg["user"], body: msg["body"]}
    # {:reply, {:ok, %{msg: msg["body"]}}, assign(socket, :user, msg["user"])}
    Logger.debug fn -> "PRESIDENTS: #{inspect presidents, pretty: true}" end
    {:reply, {:ok, %{msg: presidents()}}, socket}
  end

  def handle_in("get_presidents", _msg, socket) do
    Logger.debug fn -> "HANDLE_IN get_presidents" end
    Logger.debug fn -> "PRESIDENTS: #{inspect presidents, pretty: true}" end
    broadcast! socket, "new:msg", %{presidents: presidents()}
    # {:reply, {:ok, %{persons: presidents()}}, socket}
    # {:reply, {:ok, %{persons: []}, socket}}
    {:noreply, socket}
  end

  def presidents() do
    presidents =
      [
        {"George Washington", 1732, "Westmoreland County", "Virginia"},
        {"John Adams", 1735, "Braintree", "Massachusetts"},
        {"Thomas Jefferson", 1743, "Shadwell", "Virginia"},
        {"James Madison", 1751, "Port Conway", "Virginia"},
        {"James Monroe", 1758, "Monroe Hall", "Virginia"},
        {"Andrew Jackson", 1767, "Waxhaws Region", "South/North Carolina"},
        {"John Quincy Adams", 1767, "Braintree", "Massachusetts"},
        {"William Henry Harrison", 1773, "Charles City County", "Virginia"},
        {"Martin Van Buren", 1782, "Kinderhook", "New York"},
        {"Zachary Taylor", 1784, "Barboursville", "Virginia"},
        {"John Tyler", 1790, "Charles City County", "Virginia"},
        {"James Buchanan", 1791, "Cove Gap", "Pennsylvania"},
        {"James K. Polk", 1795, "Pineville", "North Carolina"},
        {"Millard Fillmore", 1800, "Summerhill", "New York"},
        {"Franklin Pierce", 1804, "Hillsborough", "New Hampshire"},
        {"Andrew Johnson", 1808, "Raleigh", "North Carolina"},
        {"Abraham Lincoln", 1809, "Sinking spring", "Kentucky"},
        {"Ulysses S. Grant", 1822, "Point Pleasant", "Ohio"},
        {"Rutherford B. Hayes", 1822, "Delaware", "Ohio"},
        {"Chester A. Arthur", 1829, "Fairfield", "Vermont"},
        {"James A. Garfield", 1831, "Moreland Hills", "Ohio"},
        {"Benjamin Harrison", 1833, "North Bend", "Ohio"},
        {"Grover Cleveland", 1837, "Caldwell", "New Jersey"},
        {"William McKinley", 1843, "Niles", "Ohio"},
        {"Woodrow Wilson", 1856, "Staunton", "Virginia"},
        {"William Howard Taft", 1857, "Cincinnati", "Ohio"},
        {"Theodore Roosevelt", 1858, "New York City", "New York"},
        {"Warren G. Harding", 1865, "Blooming Grove", "Ohio"},
        {"Calvin Coolidge", 1872, "Plymouth", "Vermont"},
        {"Herbert Hoover", 1874, "West Branch", "Iowa"},
        {"Franklin D. Roosevelt", 1882, "Hyde Park", "New York"},
        {"Harry S. Truman", 1884, "Lamar", "Missouri"},
        {"Dwight D. Eisenhower", 1890, "Denison", "Texas"},
        {"Lyndon B. Johnson", 1908, "Stonewall", "Texas"},
        {"Ronald Reagan", 1911, "Tampico", "Illinois"},
        {"Richard M. Nixon", 1913, "Yorba Linda", "California"},
        {"Gerald R. Ford", 1913, "Omaha", "Nebraska"},
        {"John F. Kennedy", 1917, "Brookline", "Massachusetts"},
        {"George H. W. Bush", 1924, "Milton", "Massachusetts"},
        {"Jimmy Carter", 1924, "Plains", "Georgia"},
        {"George W. Bush", 1946, "New Haven", "Connecticut"},
        {"Bill Clinton", 1946, "Hope", "Arkansas"},
        {"Barack Obama", 1961, "Honolulu", "Hawaii"},
        {"Donald Trump", 1946, "New York City", "New York"}
      ]

    for {name, year, city, state} <- presidents do
      %{name: name, year: year, city: city, state: state, selected: false}
    end

  end
end
