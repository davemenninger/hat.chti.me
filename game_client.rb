require 'gosu'
require 'thread'
require 'faye/websocket'
require 'eventmachine'

class Tutorial < Gosu::Window
  def initialize
    super 640, 480
    self.caption = "Tutorial Game"
    @font = Gosu::Font.new(20)
    @network = Network.new
    @derp = "a string"
  end

  def update
    super
    @network.dispatch_network_events_to(self)
    self.caption = "stuff"
  end

  def draw
    @font.draw("hi",10, 10, 3, 1.0, 1.0, Gosu::Color::YELLOW)
    @font.draw(@derp,10, 40, 3, 1.0, 1.0, Gosu::Color::YELLOW)
  end

  def on_derp(herp)
    @derp = herp
  end


  class Network
    def initialize
      @network_event_queue = Queue.new
      @thread = Thread.new do
        EM.run {
          ws = Faye::WebSocket::Client.new('wss://hat.chti.me/game')

          ws.on :open do |event|
            p [:open]
            ws.send('Hello, world!')
          end

          ws.on :message do |event|
            p [:message, event.data]
            push_event(:on_derp, event.data)
          end

          ws.on :close do |event|
            p [:close, event.code, event.reason]
            ws = nil
          end
        }
      end
    end

    def dispatch_network_events_to(receiver)
      @network_event_queue.size.times do
        @network_event_queue.pop.call(receiver)
      end
    end

    def push_event(symbol, *args)
      @network_event_queue.push(proc { |receiver| receiver.send(symbol, *args) })
    end
  end
end
Tutorial.new.show
