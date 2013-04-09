local SubscriberMethods = { }
local function Subscriber(fn, options)
  return {
    options = options or {},
    fn = fn,
    channel = nil,
    id = math.random(1000000000), -- sounds reasonable, rite?
    update = SubscriberMethods.update
  }
end

SubscriberMethods = {
  update = function(self, options)
    if options then
      self.fn = options.fn or self.fn
      self.options = options.options or self.options
    end
  end
}



local ChannelMethods = { }
local function Channel(namespace, parent)
  return {
    stopped = false,
    namespace = namespace,
    callbacks = {},
    channels = {},
    parent = parent,
    addSubscriber = ChannelMethods.addSubscriber,
    getSubscriber = ChannelMethods.getSubscriber,
    setPriority = ChannelMethods.setPriority,
    addChannel = ChannelMethods.addChannel,
    hasChannel = ChannelMethods.hasChannel,
    getChannel = ChannelMethods.getChannel,
    removeSubscriber = ChannelMethods.removeSubscriber,
    publish = ChannelMethods.publish,
    stopPropagation = ChannelMethods.stopPropagation
  }
end

-- Channel class and functions --
ChannelMethods = {
  addSubscriber = function(self, fn, options)
    local callback = Subscriber(fn, options)
    local priority = (#self.callbacks + 1)

    if
      options and options.priority and
      options.priority >= 0 and
      options.priority < (#self.callbacks + 1)
    then
        priority = options.priority
    end

    table.insert(self.callbacks, priority, callback)

    return callback
  end,

  getSubscriber = function(self, id)
    for i, v in pairs(self.callbacks) do
      if v.id == id then return { index = i, value = v } end
    end

    local sub

    for _, v in pairs(self.channels) do
      sub = v:getSubscriber(id)
      if sub then break end
    end

    return sub
  end,

  setPriority = function(self, id, priority)
    local callback = self:getSubscriber(id)

    if callback.value then
      table.remove(self.callbacks, callback.index)
      table.insert(self.callbacks, priority, callback.value)
    end
  end,

  addChannel = function(self, namespace)
    self.channels[namespace] = Channel(namespace, self)
    return self.channels[namespace]
  end,

  hasChannel = function(self, namespace)
    return namespace and self.channels[namespace] and true
  end,

  getChannel = function(self, namespace)
    return self.channels[namespace] or self:addChannel(namespace)
  end,

  removeSubscriber = function(self, id)
    local callback = self:getSubscriber(id)

    if callback and callback.value then
      for _, v in pairs(self.channels) do
        v:removeSubscriber(id)
      end

      return table.remove(self.callbacks, callback.index)
    end
  end,

  publish = function(self, ...)
    local result = {}

    for _, v in pairs(self.callbacks) do
      if self.stopped then return result end

      -- if it doesn't have a predicate, or it does and it's true then run it
      if not v.options.predicate or (v.options.predicate and v.options.predicate(...)) then

         -- just take the first result and insert it into the result table
        local val = v.fn(...)
        table.insert(result, val)
      end
    end

    if self.parent then
      for _,v in pairs(self.parent:publish(...)) do table.insert(result, v) end
    end

    return result
  end,

  stopPropagation = function(self)
    self.stopped = true
  end
}



-- Mediator class and functions --
local MediatorMethods = { }
local Mediator = setmetatable(
{
  Channel = Channel,
  Subscriber = Subscriber
},
{
  __call = function (fn, options)
    return {
      channel = Channel('root'),
      getChannel = MediatorMethods.getChannel,
      subscribe  = MediatorMethods.subscribe,
      getSubscriber = MediatorMethods.getSubscriber,
      removeSubscriber  = MediatorMethods.removeSubscriber,
      publish = MediatorMethods.publish
    }
  end
})

MediatorMethods = {
  getChannel = function(self, channelNamespace)
    local channel = self.channel

    for i, v in pairs(channelNamespace) do
      channel = channel:getChannel(v)
    end

    return channel;
  end,

  subscribe = function(self, channelNamespace, fn, options)
    return self:getChannel(channelNamespace):addSubscriber(fn, options)
  end,

  getSubscriber = function(self, id, channelNamespace)
    return self:getChannel(channelNamespace):getSubscriber(id)
  end,

  removeSubscriber = function(self, id, channelNamespace)
    return self:getChannel(channelNamespace):removeSubscriber(id)
  end,

  publish = function(self, channelNamespace, ...)
    return self:getChannel(channelNamespace):publish(...)
  end
}

return Mediator
