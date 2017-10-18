defmodule ExAudit.Test.Repo.Migrations.InitialTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string

      timestamps(type: :utc_datetime)
    end

    create table(:blog_post) do
      add :title, :string
      add :author_id, references(:users, on_update: :update_all, on_delete: :delete_all)
      add :sections, :map

      timestamps(type: :utc_datetime)
    end

    create table(:comments) do
      add :author_id, references(:users, on_update: :update_all, on_delete: :delete_all)
      add :body, :text

      timestamps(type: :utc_datetime)
    end

    create table(:versions) do
      # The patch in Erlang External Term Format
      add :patch, :binary

      # supports UUID and other types as well
      add :entity_id, :integer 

      # name of the table the entity is in
      add :entity_schema, :string 

      # type of the action that has happened to the entity (created, updated, deleted)
      add :action, :string

      # when has this happened
      add :recorded_at, :datetime

      # optional fields that you can define yourself
      # for example, it's a good idea to track who did the change
      add :actor_id, references(:users, on_update: :update_all, on_delete: :nilify_all)
    end
  end
end