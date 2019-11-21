# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Nodeattr Server.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Nodeattr Server is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Nodeattr Server. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Nodeattr Server, please visit:
# https://github.com/openflighthpc/nodeattr-server
#===============================================================================

require 'sinja/method_override'

use Sinja::MethodOverride
register Sinja

resource :nodes, pkre: /[[:alnum:]]+/ do
  helpers do
    def find(id)
      Node.find(id)
    end
  end

  index do
    Node.all
  end

  show

  create do |attr|
    node = Node.create(**attr)
    [node.id, node]
  end

  update do |attr|
    resource.update(**attr)
    resource
  end

  destroy { resource.destroy }

  has_one :cluster do
    pluck { resource.cluster }

    graft(sideload_on: :create) do |rio|
      Cluster.find(rio[:id])
    end
  end

  has_many :group do
    fetch { resource.groups }

    merge(sideload_on: :create) do |rios|
      new_groups = rios.map { |rio| Group.find(rio[:id]) }
      resource.groups << new_groups
      resource.save!
      true
    end

    subtract do |rios|
      ids = rios.map { |rio| rio[:id] }
      resource.groups = resource.groups.reject { |g| ids.include?(g.id.to_s) }
      resource.save!
      true
    end

    replace(sideload_on: :update) do |rios|
      groups = rios.map { |rio| Group.find(rio) }
      resource.groups = groups
      resource.save!
      true
    end

    clear(sideload_on: :update) do
      resource.groups = []
      resource.save
      true
    end
  end
end

resource :groups, pkre: /[[:alnum:]]+/ do
  helpers do
    def find(id)
      Group.find(id)
    end
  end

  index do
    Group.all
  end

  show

  create do |attr|
    group = Group.create(**attr)
    [group.id, group]
  end

  # NOTE: Groups Currently can not be updated
  # update do |attr|
  #   resource.update(**attr)
  # end

  destroy { resource.destroy }

  has_many :nodes do
    fetch { resource.nodes }
  end
end

resource :clusters, pkre: /[[:alnum:]]+/ do
  helpers do
    def find(id)
      Cluster.find(id)
    end
  end

  index do
    Cluster.all
  end

  show

  create do |attr|
    cluster = Cluster.create(**attr)
    [cluster.id, cluster]
  end

  update do |attr|
    resource.update(**attr)
    resource
  end

  destroy { resource.destroy }

  has_many :nodes do
    fetch { resource.nodes }
  end
end
