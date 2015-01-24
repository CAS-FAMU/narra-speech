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

require 'spec_helper'

describe Narra::Speech::Generator do
  before(:each) do
    # nothing to do
  end

  it 'can be instantiated' do
    expect(Narra::Speech::Generator.new(@url)).to be_an_instance_of(Narra::Speech::Generator)
  end

  it 'should have accessible fields' do
    expect(Narra::Speech::Generator.identifier).to match(:speech)
    expect(Narra::Speech::Generator.title).to match('NARRA Speech To Text Generator')
    expect(Narra::Speech::Generator.description).to match('NARRA Speech To Text Generator using AT&T Speech API to transcribe audio tracks')
  end
end