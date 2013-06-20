require "./deluge/version"

class String
  def around(before, after)
    self.insert(0, before).insert(-1, after)
  end
end

module Deluge
  TORRENT_PROPERTIES = :state, :save_path, :tracker, :tracker_status, :next_announce,
                       :name, :total_size, :progress, :num_seeds, :total_seeds,
                       :num_peers, :total_peers, :eta, :download_payload_rate,
                       :upload_payload_rate, :ratio, :distributed_copies, :num_pieces,
                       :piece_length, :total_done, :files, :file_priorities, :file_progress,
                       :peers, :is_seed, :is_finished, :active_time, :seeding_time,
                       :id, :up_speed, :seeds, :availability,
                       :size, :seed_time, :active
  def self.all_fields
    Deluge::TORRENT_PROPERTIES.map(&:to_s).map{|prop| prop.insert(-1,':').gsub(/_/,' ') }
  end
  def self.all_fields_joined
    all_fields.join('|').around('(',')')
  end

  class Client
    attr_accessor :deluge_console_command
    def initialize(deluge_console_command='deluge-console')
      @deluge_console_command = deluge_console_command
    end

    def find(*id)
      make_me_torrents_from_this_junk(run("info #{id}"))
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
      make_me_torrents_from_this_junk(run('info'))
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
      `#{@deluge_console_command} #{command}`
    end

    def method_missing(method, *args)
      run "#{method} #{args}"
    end

  private
    def parse_torrent_string(torrent)
      torrent.gsub(Regexp.new(Deluge.all_fields_joined,'i')) do |m|
        "\n#{m}"
      end.split("\n").map(&:strip).reject(&:empty?).map do |param|
        pair = param.split(':')
        { pair[0] => pair[1..-1].join(':')}
      end.reduce({}) do |sum, elem|
        sum.merge(elem)
      end
    end

    def make_me_torrents_from_this_junk(junk)
      junk.split("\n \n").map do |torrent|
        torrent_properties_hash = parse_torrent_string(torrent)
        Torrent.new(self, torrent_properties_hash)
      end
    end
  end

  class Torrent
    attr_accessor *Deluge::TORRENT_PROPERTIES
    def initialize(client, attributes)
      @client = client
      attributes.each do |pair|
        symbol = pair[0].to_s.gsub(/ /,'_').downcase.to_sym
        self.send "#{symbol}=", pair[1]
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
