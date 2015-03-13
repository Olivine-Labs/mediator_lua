describe("mediator", function()
  local Mediator = require 'mediator'
  local c, testfn, testfn2, testfn3

  before_each(function()
    m = Mediator()
    c = Mediator.Channel("test")
    testfn = function() end
    testfn2 = function() end
    testfn3 = function() end
  end)

  after_each(function()
    m = nil
    c = nil
    testfn = nil
    testfn2 = nil
    testfn3 = nil
  end)

  it("can register subscribers", function()
    local sub1 = c:addSubscriber(testfn)

    assert.are.equal(#c.callbacks, 1)
    assert.are.equal(c.callbacks[1].fn, testfn)
  end)

  it("can register lots of subscribers", function()
    local sub1 = c:addSubscriber(testfn)
    local sub2 = c:addSubscriber(testfn2)

    assert.are.equal(#c.callbacks, 2)
    assert.are.equal(c.callbacks[2].fn, sub2.fn)
  end)

  it("can register subscribers with specified priorities", function()
    local sub1 = c:addSubscriber(testfn)
    local sub2 = c:addSubscriber(testfn2)
    local sub3 = c:addSubscriber(testfn3, { priority = 1 })

    assert.are.equal(c.callbacks[1].fn, sub3.fn)
  end)

  it("can return subscribers", function()
    local sub1 = c:addSubscriber(testfn)
    local sub2 = c:addSubscriber(testfn2)

    gotten = c:getSubscriber(sub1.id)

    assert.are.equal(gotten.value, sub1)
  end)

  it("can change subscriber priority forward after being added", function()
    local sub1 = c:addSubscriber(testfn)
    local sub2 = c:addSubscriber(testfn2)

    c:setPriority(sub2.id, 1)

    assert.are.equal(c.callbacks[1], sub2)
  end)

  it("can change subscriber priority backwards after being added", function()
    local sub1 = c:addSubscriber(testfn)
    local sub2 = c:addSubscriber(testfn2)

    c:setPriority(sub1.id, 2)

    assert.are.equal(c.callbacks[2], sub1)
  end)

  it("can add subchannels", function()
    c:addChannel("level2")
    assert.are_not.equal(c.channels["level2"], nil)
  end)

  it("can check if a subchannel has been added", function()
    c:addChannel("level2")
    assert.is.truthy(c:hasChannel("level2"), true)
  end)

  it("can return channels", function()
    c:addChannel("level2")
    assert.is_not.equal(c:getChannel("level2"), nil)
  end)

  it("can remove subscribers by id", function()
    local sub1 = c:addSubscriber(testfn)
    local sub2 = c:addSubscriber(testfn2)

    c:removeSubscriber(sub2.id)

    assert.is.equal(c:getSubscriber(sub2.id), nil)
  end)

  it("can return a subscriber registered to a subchannel", function()
    c:addChannel("level2")

    local sub1 = c.channels["level2"]:addSubscriber(testfn)

    gotten = c:getSubscriber(sub1.id)

    assert.are.equal(gotten.value, sub1)
  end)

  it("can remove a subscriber registered to a subchannel", function()
    c:addChannel("level2")

    local sub1 = c.channels["level2"]:addSubscriber(testfn)

    c:removeSubscriber(sub1.id)

    assert.is.equal(c.channels["level2"]:getSubscriber(sub1.id), nil)
  end)

  it("can publish to a channel", function()
    local olddata = { test = false }
    local data = { test = true }

    local assertFn = function(data)
      olddata = data
    end

    local sub1 = c:addSubscriber(assertFn)
    c:publish({}, data)

    assert.is.truthy(olddata.test)
  end)

  it("ignores if you publish to a nonexistant subchannel", function()
    assert.is_not.error(function() m:publish({ "nope" }, data) end)
  end)

  it("ignores if you publish to a nonexistant subchannel with subchannels", function()
    assert.is_not.error(function() m:publish({ "nope", "wat" }, data) end)
  end)

  it("sends all the publish arguments to subscribers", function()
    local data = { test = true }
    local arguments

    local assertFn = function(data, wat, seven)
      arguments = { data, wat, seven }
    end

    local sub1 = c:addSubscriber(assertFn)
    c:publish({}, "test", data, "wat", "seven")

    assert.are.equal(#arguments, 3)
  end)

  it("can stop propagation", function()
    local olddata = { test = 0 }
    local data = { test = 1 }
    local data2 = { test = 2 }

    local assertFn = function(data)
      olddata = data
    end

    local assertFn2 = function(data)
      olddata = data2
    end

    local sub1 = c:addSubscriber(assertFn)
    local sub2 = c:addSubscriber(assertFn2)

    c:publish({}, data)

    assert.are.equal(olddata.test, 1)
  end)

  it("publishes to parent channels", function()
    local olddata = { test = false }
    local data = { test = true }

    local assertFn = function(...)
      olddata = data
    end

    c:addChannel("level2")

    local sub1 = c.channels["level2"]:addSubscriber(assertFn)

    c.channels["level2"]:publish({}, data)

    assert.is.truthy(olddata.test)
  end)

  it("can return a channel from the mediator level", function()
    assert.is_not.equal(m:getChannel({"test", "level2"}), nil)
    assert.are.equal(m:getChannel({"test", "level2"}), m:getChannel({"test"}):getChannel("level2"))
  end)

  it("can publish to channels from the mediator level", function()
    local assertFn = function(data, channel)
      olddata = data
    end

    local s = m:subscribe({"test"}, assertFn)

    assert.is_not.equal(m:getChannel({ "test" }):getSubscriber(s.id), nil)
  end)

  it("publishes to the proper subchannel", function()
    local a = spy.new(function() end)
    local b = spy.new(function() end)

    m:subscribe({ "request", "a" }, a)
    m:subscribe({ "request", "b" }, b)

    m:publish({ "request", "a" })
    m:publish({ "request", "b" })

    assert.spy(a).was.called(1)
    assert.spy(b).was.called(1)
  end)

  it("can return a subscriber at the mediator level", function()
    local assertFn = function(data, channel)
      olddata = data
    end

    local s = m:subscribe({"test"}, assertFn)

    assert.is_not.equal(m:getSubscriber(s.id, { "test" }), nil)
  end)


  it("can remove a subscriber at the mediator level", function()
    local assertFn = function(data)
      olddata = data
    end

    local s = m:subscribe({"test"}, assertFn)

    assert.is_not.equal(m:getSubscriber(s.id, { "test" }), nil)

    m:removeSubscriber(s.id, {"test"})

    assert.are.equal(m:getSubscriber(s.id, { "test" }), nil)
  end)

  it("can publish to a subscriber at the mediator level", function()
    local olddata = "wat"

    local assertFn = function(data)
      olddata = data
    end

    local s = m:subscribe({"test"}, assertFn)
    m:publish({ "test" }, "hi")

    assert.are.equal(olddata, "hi")
  end)

  it("can publish a subscriber to all parents at the mediator level", function()
    local olddata = "wat"
    local olddata2 = "watwat"

    local assertFn = function(data)
      olddata = data
      return nil, true
    end

    local assertFn2 = function(data)
      olddata2 = data
      return nil, true
    end

    c:addChannel("level2")

    local s = m:subscribe({ "test", "level2" }, assertFn)
    local s2 = m:subscribe({ "test" }, assertFn2)

    m:publish({ "test", "level2" }, "didn't read lol")

    assert.are.equal(olddata, "didn't read lol")
    assert.are.equal(olddata2, "didn't read lol")
  end)

  it("has predicates", function()
    local olddata = "wat"
    local olddata2 = "watwat"

    local assertFn = function(data)
      olddata = data
    end

    local assertFn2 = function(data)
      olddata2 = data
    end

    local predicate = function()
      return false
    end

    c:addChannel("level2")

    local s = m:subscribe({"test","level2"}, assertFn)
    local s2 = m:subscribe({"test"}, assertFn2, { predicate = predicate })

    m:publish({"test", "level2"}, "didn't read lol")

    assert.are.equal(olddata, "didn't read lol")
    assert.are_not.equal(olddata2, "didn't read lol")
  end)
end)
