#
# Copyright (C) 2014 CAS / FAMU
#
# This file is part of Narra Core.
#
# Narra Core is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Narra Core is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Narra Core. If not, see <http://www.gnu.org/licenses/>.
#
# Authors:
#

require 'narra/spi'
require 'narra/tools'

require 'att/codekit'
require 'streamio-ffmpeg'

module Narra
  module Speech
    class Generator < Narra::SPI::Generator

      @identifier = :speech
      @title = 'Speech To Text'
      @description = 'Speech To Text Generator using AT&T Speech API to transcribe audio tracks'

      def self.valid?(item_to_check)
        (item_to_check.type.equal?(:video) || item_to_check.type.equal?(:audio)) && !item_to_check.url_audio_proxy.nil?
      end

      def generate
        # prepare audio file
        chunks = prepare_audio_files
        # analyse when valid
        if !chunks.nil?
          convert_speech_to_text(chunks)
        end
        # clean env
        clean_audio_files
      end

      def prepare_audio_files
        # temporary files
        @temporary_raw = Narra::Tools::Settings.storage_temp + '/' + @item._id.to_s + '_speech_raw'
        @temporary_convert = []
        @chunks_duration = 5
        # progress
        set_progress(0.05)
        # download
        File.open(@temporary_raw, 'wb') do |file|
          file.write @item.audio_proxy.body
        end
        # get ffmpeg object
        audio = FFMPEG::Movie.new(@temporary_raw)
        # progress
        set_progress(0.10)
        # return audio
        if audio.valid?
          # calculate steps
          steps = (audio.duration / @chunks_duration).to_i
          # transcode
          (0..steps).each do |step|
            # push into array
            @temporary_convert << { file: Narra::Tools::Settings.storage_temp + '/' + @item._id.to_s + '_speech_convert-' + (step*@chunks_duration).to_s + '.wav', in: step*@chunks_duration, out: (step+1)*@chunks_duration }
            # transcode
            audio.transcode(@temporary_convert[step][:file], '-ac 1 -t ' + @chunks_duration.to_s + ' -ss ' + @temporary_convert[step][:in].to_s)
          end
          # progress
          set_progress(0.40)
          # return
          return @temporary_convert
        else
          return nil
        end
      end

      def clean_audio_files
        # delete raw files
        FileUtils.rm_f(@temporary_raw)
        # delete transcodes
        @temporary_convert.each do |chunk|
          FileUtils.rm_f(chunk[:file])
        end
        # progress
        set_progress(0.95)
      end

      def convert_speech_to_text(chunks)
        # credentials
        client_id = ENV['ATT_CLIENT_ID']
        client_secret = ENV['ATT_CLIENT_SECRET']
        # fully-qualified domain name to: https://api.att.com
        fqdn = 'https://api.att.com'
        # service for requesting an OAuth access token.
        clientcred = Att::Codekit::Auth::ClientCred.new(fqdn, client_id, client_secret)
        # OAuth access token using the API scope set to SPEECH.
        token = clientcred.createToken('SPEECH')
        # Create the service for interacting with the Speech API.
        speech = Att::Codekit::Service::SpeechService.new(fqdn, token)
        # progress
        set_progress(0.60)
        # iterate over chunks
        chunks.each do |audio|
          # Convert the content of the audio file to text.
          response = speech.toText(audio[:file])
          # add metadata
          add_meta(name: 'subtitle-' + audio[:in].to_s, value: response.nbest[0].result, marks: [{in: audio[:in].to_f, out: audio[:out].to_f}]) unless response.nil? || response.status != 'OK'
        end
        # progress
        set_progress(0.90)
      end
    end
  end
end
