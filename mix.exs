defmodule Exblog.Mixfile do
  use Mix.Project

  def project do
    [ app: :exblog,
      version: "0.0.1",
      dynamos: [Exblog.Dynamo],
      compilers: [:elixir, :dynamo, :app],
      env: [prod: [compile_path: "ebin"]],
      compile_path: "tmp/#{Mix.env}/exblog/ebin",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:cowboy, :dynamo, :httpotion],
      mod: { Exblog, [] } ]
  end

  defp deps do
    [ { :cowboy, github: "extend/cowboy" },
      { :dynamo, github: "elixir-lang/dynamo" },
      { :ossp_uuid, github: "yrashk/erlang-ossp-uuid" },
      { :httpotion, github: "myfreeweb/httpotion"},
      { :jsonex, "2.0", github: "marcelog/jsonex"},
      { :ex_doc, github: "elixir-lang/ex_doc" } ]
  end
end
