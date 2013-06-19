# require "./deluge/version"

module Deluge
  class Client
    attr_accessor :deluge_console_command
    def initialize(deluge_console_command='deluge-console')
      @deluge_console_command = deluge_console_command
    end

    def find(*id)
      make_me_a_torrent_or_torrents_from_this_junk(run("info #{id}"))
    end

    def remove(*id)
      run("rm #{id}")
    end
    def pause(*id)
      run("pause #{id}")
    end
    def recheck(*id)
      run("recheck #{id}")
    end
    def resume(*id)
      run("resume #{id}")
    end

    def add link, path=nil
      run("add #{path ? '-p '+ path : ''} #{link}")
    end

    def all
      make_me_a_torrent_or_torrents_from_this_junk(run('info'))
    end

    def get(value)
      run("config #{value}")
    end

    def set(key,value)
      run("config -set #{key} #{value}")
    end

    def cache
      run 'cache'
    end

    def halt
      run 'halt'
    end

    def run(command)
      system `#{deluge_console_command} '#{command}`
    end

    def method_missing(method, *args)
      run "#{method} #{args}"
    end
  private
    def make_me_a_torrent_or_torrents_from_this_junk(junk)
      junk.split("\n \n").map do |torrent|
        torrent.split("\n").map(&:strip).reject(&:empty?).map do |param|
          param.split(':')
        end.map do |pair|
          { pair[0] => pair[1..-1].join(':')}
        end
      end.map do |torrent|
        torrent.reduce({}) do |sum, elem|
          sum.merge(elem)
        end
      end.map do |torrent|
        Torrent.new(self, torrent)
      end
    end
  end

  class Torrent
    attr_accessor :client, :Name, :ID, :State, :Seeds, :Size, :Seed_time, :Tracker_status, :Progress
    def initialize(client, attributes)
      @client = client
      attributes.each do |pair|
        self.send "#{pair[0]}=", pair[1]
      end
    end
    def remove
      client.remove(@id)
    end
    def pause
      client.pause(@id)
    end
    def recheck
      client.recheck(@id)
    end
    def resume
      client.resume(@id)
    end
  end
end
