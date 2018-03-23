defmodule Relay.Marathon.TaskTest do
  use ExUnit.Case, async: true

  alias Relay.Marathon.{App, Task}

  @test_app %App{
    id: "/mc2",
    labels: %{
      "HAPROXY_0_REDIRECT_TO_HTTPS" => "true",
      "HAPROXY_0_VHOST" => "mc2.example.org",
      "HAPROXY_GROUP" => "external",
      "MARATHON_ACME_0_DOMAIN" => "mc2.example.org"
    },
    networking_mode: :"container/bridge",
    ports_list: [80],
    port_indices_in_group: [0],
    version: "2017-11-08T15:06:31.066Z"
  }

  @test_task %{
    "ipAddresses" => [
      %{
        "ipAddress" => "172.17.0.9",
        "protocol" => "IPv4"
      }
    ],
    "stagedAt" => "2018-02-16T14:29:06.487Z",
    "state" => "TASK_RUNNING",
    "ports" => [
      15979
    ],
    "startedAt" => "2018-02-16T14:29:09.605Z",
    "version" => "2017-11-09T08:43:59.890Z",
    "id" => "mc2.be753491-1325-11e8-b5d6-4686525b33db",
    "appId" => "/mc2",
    "slaveId" => "d25be2a7-61ce-475f-8b07-d56400c8d744-S1",
    "host" => "10.70.4.100"
  }

  @test_task_staging %{
    "stagedAt" => "2018-03-02T09:35:04.169Z",
    "state" => "TASK_STAGING",
    "ports" => [
      10013
    ],
    "startedAt" => nil,
    "version" => "2018-03-02T09:35:00.998Z",
    "id" => "mc2.fc99770b-1dfc-11e8-a2a6-1653cd73b500",
    "appId" => "/mc2",
    "slaveId" => "7e76e0e4-f16c-4d63-a629-dd05d137a223-S2",
    "host" => "10.70.4.100"
  }

  @test_event %{
    "slaveId" => "7e76e0e4-f16c-4d63-a629-dd05d137a223-S2",
    "taskId" => "mc2.8bef4d3e-1dfc-11e8-a2a6-1653cd73b500",
    "taskStatus" => "TASK_KILLED",
    "message" => "Container exited with status 137",
    "appId" => "/mc2",
    "host" => "10.0.91.101",
    "ipAddresses" => [
      %{
        "ipAddress" => "10.0.91.101",
        "protocol" => "IPv4"
      }
    ],
    "ports" => [
      25443
    ],
    "version" => "2018-03-02T09:31:54.763Z",
    "eventType" => "status_update_event",
    "timestamp" => "2018-03-02T09:35:21.147Z"
  }

  test "from definition" do
    assert Task.from_definition(@test_app, @test_task) == %Task{
             address: "10.70.4.100",
             app_id: "/mc2",
             id: "mc2.be753491-1325-11e8-b5d6-4686525b33db",
             ports: [15979],
             version: "2018-02-16T14:29:09.605Z"
           }
  end

  test "from definition staging" do
    assert %Task{version: "2018-03-02T09:35:04.169Z"} =
             Task.from_definition(@test_app, @test_task_staging)
  end

  test "from definition container networking" do
    app = %{@test_app | networking_mode: :container}

    assert Task.from_definition(app, @test_task) == %Task{
             address: "172.17.0.9",
             app_id: "/mc2",
             id: "mc2.be753491-1325-11e8-b5d6-4686525b33db",
             ports: [80],
             version: "2018-02-16T14:29:09.605Z"
           }
  end

  test "from event" do
    assert Task.from_event(@test_app, @test_event) == %Task{
             id: "mc2.8bef4d3e-1dfc-11e8-a2a6-1653cd73b500",
             address: "10.0.91.101",
             app_id: "/mc2",
             ports: [25443],
             version: "2018-03-02T09:31:54.763Z"
           }
  end

  test "endpoint" do
    task = Task.from_definition(@test_app, @test_task)

    assert Task.endpoint(task, 0) == {"10.70.4.100", 15979}
  end
end
