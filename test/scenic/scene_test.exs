#
#  re-re-Created by Boyd Multerer on May 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
#

defmodule Scenic.SceneTest do
  use ExUnit.Case, async: false
  doctest Scenic
  alias Scenic.ViewPort
  alias Scenic.Scene
  alias Scenic.Animation
  alias Scenic.Graph
  alias Scenic.Primitive
  import Scenic.Primitives
#  import IEx

  @not_activated        :__not_activated__


  @driver_registry      :driver_registry
  @viewport_registry    :viewport_registry


  @graph  Graph.build()
  |> rect({{10,11},100,200}, id: :rect)

  @graph_2  Graph.build()
  |> triangle({{20, 300}, {400, 300}, {400, 0}}, id: :triangle)


  #============================================================================
  # faux scene module callbacks...

  def init( opts ) do
    assert opts == [1,2,3]
    {:ok, :init_state}
  end

  def handle_info( msg, _state ) do
    {:noreply, msg}
  end
  def handle_set_root( _vp, :args, _state ) do
    {:noreply, :set_root_state}
  end

  def handle_lose_root( _vp, _state ) do
    {:noreply, :lose_root_state}
  end

  def handle_call( msg, _from, _state ) do
    {:reply, msg, msg}
  end


  #============================================================================
  # child_spec
  # need a custom child_spec because there can easily be multiple scenes running at the same time
  # they are all really Scenic.Scene as the GenServer module, so need to use differnt ids

  test "child_spec uses the scene module and id - no args" do
    %{
      id:       id,
      start:    {Scene, :start_link, [__MODULE__, :args, []]},
      type:     :worker,
      restart:  :permanent,
      shutdown: 500
    } = Scene.child_spec({__MODULE__, :args, []})
    assert is_reference(id)
  end

  #============================================================================
  test "init stores the scene name in the process dictionary" do
    ref = make_ref()
    Scene.init( {__MODULE__, [1,2,3], [scene_ref: ref]} )
    # verify the process dictionary
    assert Process.get(:scene_ref) == ref
  end

  test "init stores the scene reference in the process dictionary" do
    Scene.init( {__MODULE__, [1,2,3], [name: :scene_name]} )
    # verify the process dictionary
    assert Process.get(:scene_ref) == :scene_name
  end

  test "init sends root_up message if vp_dynamic_root is set" do
    self = self()
    Scene.init( {__MODULE__, [1,2,3], [name: :scene_name, vp_dynamic_root: self]} )
    # verify the message
    assert_receive( {:"$gen_cast", {:dyn_root_up, :scene_name, self}} )
  end

  test "init does not send root_up message if vp_dynamic_root is clear" do
    self = self()
    Scene.init( {__MODULE__, [1,2,3], [name: :scene_name]} )
    # verify the message
    refute_receive( {:"$gen_cast", {:dyn_root_up, _, _}} )
  end

  test "init stores parent_pid in the process dictionary if set" do
    ref = make_ref()
    Scene.init( {__MODULE__, [1,2,3], [scene_ref: ref, parent: self()]} )
    # verify the process dictionary
    assert Process.get(:parent_pid) == self()
  end

  test "init stores nothing in the process dictionary if parent clear" do
    ref = make_ref()
    Scene.init( {__MODULE__, [1,2,3], [scene_ref: ref]} )
    # verify the process dictionary
    assert Process.get(:parent_pid) == nil
  end

  test "init sends self :after_init" do
    Scene.init( {__MODULE__, [1,2,3], [name: :scene_name]} )
    assert_receive( {:"$gen_cast", :after_init} )
  end
  test "init call mod.init and returns first round of state" do
    self = self()
    {:ok, %{
      raw_scene_refs: %{},      
      dyn_scene_pids: %{},
      dyn_scene_keys: %{},

      parent_pid: self,
      children: %{},

      scene_module: __MODULE__,

      scene_state: :init_state,
      scene_ref: :scene_name,
      supervisor_pid: nil,
      dynamic_children_pid: nil,
      activation: @not_activated
    }} = Scene.init( {__MODULE__, [1,2,3], [name: :scene_name, parent: self]} )
  end

  #============================================================================
  # handle_info
  
  test "handle_info sends unhandles messages to the module" do
    {:noreply, new_state} = assert Scene.handle_info(:abc, %{
      scene_module: __MODULE__,
      scene_state: nil
    })
    assert new_state.scene_state == :abc
  end


  #============================================================================
  # handle_call
  
  test "handle_call :set_root calls set_root on module" do
    {:reply, resp, new_state} = assert Scene.handle_call(
      {:set_root, :args}, self(), %{
      scene_module: __MODULE__,
      scene_state: nil,
      activation: nil
    })
    assert resp == :ok
    assert new_state.scene_state == :set_root_state
    assert new_state.activation == :args
  end

  test "handle_call sends unhandles messages to the module" do
    {:reply, resp, new_state} = assert Scene.handle_call(
      :lose_root, self(), %{
      scene_module: __MODULE__,
      scene_state: nil,
      activation: :args
    })
    assert resp == :ok
    assert new_state.scene_state == :lose_root_state
    assert new_state.activation == @not_activated
  end

  test "handle_call sends unhandled messages to mod" do
    {:reply, resp, new_state} = assert Scene.handle_call(
      :other, self(), %{
      scene_module: __MODULE__,
      scene_state: nil,
    })
    assert resp == :other
    assert new_state.scene_state == :other
  end


  #============================================================================
  # handle_cast

  test "handle_cast :set_root calls the mod set root handler" do
    {:noreply, new_state} = assert Scene.handle_cast(
      {:set_root, :args}, self(), %{
      scene_module: __MODULE__,
      scene_state: nil,
      activation: nil
    })
    assert resp == :ok
    assert new_state.scene_state == :set_root_state
    assert new_state.activation == :args
  end


end

















