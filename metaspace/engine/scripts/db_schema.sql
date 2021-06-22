-- This file is autogenerated. Do not edit it directly.
-- To regenerate this file, run 'yarn run gen-sql-schema' in the graphql project

CREATE EXTENSION "uuid-ossp";
CREATE SCHEMA IF NOT EXISTS graphql;

CREATE TABLE "graphql"."credentials" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v1mc(), 
  "hash" text, 
  "google_id" text, 
  "api_key" text, 
  "api_key_last_updated" TIMESTAMP, 
  "email_verification_token" text, 
  "email_verification_token_expires" TIMESTAMP, 
  "email_verified" boolean NOT NULL DEFAULT false, 
  "reset_password_token" text, 
  "reset_password_token_expires" TIMESTAMP, 
  CONSTRAINT "PK_756d8ef9c32d9efde516fb3fcfd" PRIMARY KEY ("id")
);

CREATE TABLE "public"."molecular_db" (
  "id" SERIAL NOT NULL, 
  "name" text NOT NULL, 
  "version" text NOT NULL, 
  "created_dt" TIMESTAMP NOT NULL, 
  "molecule_link_template" text, 
  "description" text, 
  "full_name" text, 
  "link" text, 
  "citation" text, 
  "is_public" boolean NOT NULL DEFAULT false, 
  "archived" boolean NOT NULL DEFAULT false, 
  "targeted" boolean NOT NULL DEFAULT false, 
  "group_id" uuid, 
  "default" boolean NOT NULL DEFAULT false, 
  CONSTRAINT "molecular_db_uindex" UNIQUE ("group_id", 
  "name", 
  "version"), 
  CONSTRAINT "PK_1841660e7287891634f1e73d7f2" PRIMARY KEY ("id")
);

CREATE TABLE "public"."molecule" (
  "id" SERIAL NOT NULL, 
  "mol_id" text NOT NULL, 
  "mol_name" text NOT NULL, 
  "formula" text NOT NULL, 
  "inchi" text, 
  "moldb_id" integer NOT NULL, 
  CONSTRAINT "PK_d9e3f72bdba412e5cbeea2a1915" PRIMARY KEY ("id")
);

CREATE INDEX "IDX_01280507c3bd02500e2861fb27" ON "public"."molecule" (
  "moldb_id"
) ;

CREATE TABLE "graphql"."group" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v1mc(), 
  "name" text NOT NULL, 
  "short_name" text NOT NULL, 
  "url_slug" text, 
  "group_description" text NOT NULL DEFAULT '', 
  CONSTRAINT "PK_e1cf69cf0597daf3f445ad6cd71" PRIMARY KEY ("id")
);

CREATE TABLE "graphql"."user_group" (
  "user_id" uuid NOT NULL, 
  "group_id" uuid NOT NULL, 
  "role" text NOT NULL, 
  "primary" boolean NOT NULL DEFAULT true, 
  CONSTRAINT "PK_dfec383f504900f9a67e582bf2e" PRIMARY KEY ("user_id", 
  "group_id")
);

CREATE TABLE "graphql"."project" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v1mc(), 
  "name" text NOT NULL, 
  "url_slug" text, 
  "is_public" boolean NOT NULL DEFAULT false, 
  "created_dt" TIMESTAMP NOT NULL, 
  "project_description" text, 
  "review_token" text, 
  "review_token_created_dt" TIMESTAMP, 
  "publish_notifications_sent" integer NOT NULL DEFAULT 0, 
  "publication_status" text NOT NULL DEFAULT 'UNPUBLISHED', 
  "published_dt" TIMESTAMP, 
  "external_links" json, 
  CONSTRAINT "PK_486ca2f737a2dfd930e46d254aa" PRIMARY KEY ("id")
);

CREATE TABLE "graphql"."user_project" (
  "user_id" uuid NOT NULL, 
  "project_id" uuid NOT NULL, 
  "role" text NOT NULL, 
  CONSTRAINT "PK_43a9ad6dfeb462859c77919609d" PRIMARY KEY ("user_id", 
  "project_id")
);

CREATE INDEX "IDX_d99bb7781b0c98876331d19387" ON "graphql"."user_project" (
  "project_id"
) ;

CREATE TABLE "graphql"."dataset" (
  "id" text NOT NULL, 
  "user_id" uuid NOT NULL, 
  "description" text, 
  "group_id" uuid, 
  "group_approved" boolean NOT NULL DEFAULT false, 
  "pi_name" text, 
  "pi_email" text, 
  "external_links" json, 
  CONSTRAINT "PK_64fe57c57282f8de5caf4adb72f" PRIMARY KEY ("id")
);

CREATE TABLE "graphql"."dataset_project" (
  "dataset_id" text NOT NULL, 
  "project_id" uuid NOT NULL, 
  "approved" boolean NOT NULL, 
  CONSTRAINT "PK_9511b6cda2f4d4299812106cdd4" PRIMARY KEY ("dataset_id", 
  "project_id")
);

CREATE TABLE "graphql"."user" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v1mc(), 
  "name" text, 
  "email" text, 
  "not_verified_email" text, 
  "role" text NOT NULL DEFAULT 'user', 
  "credentials_id" uuid NOT NULL, 
  CONSTRAINT "REL_1b5eb1327a74d679537bdc1fa5" UNIQUE ("credentials_id"), 
  CONSTRAINT "PK_ea80e4e2bf12ab8b8b6fca858d7" PRIMARY KEY ("id")
);

CREATE TABLE "graphql"."coloc_job" (
  "id" uuid NOT NULL DEFAULT uuid_generate_v1mc(), 
  "ds_id" text NOT NULL, 
  "moldb_id" integer NOT NULL, 
  "fdr" numeric(2,2) NOT NULL, 
  "algorithm" text NOT NULL, 
  "start" TIMESTAMP NOT NULL, 
  "finish" TIMESTAMP NOT NULL, 
  "error" text, 
  "sample_ion_ids" integer array NOT NULL, 
  CONSTRAINT "PK_0d9546a0ec598ef6ca4bd835fbf" PRIMARY KEY ("id")
);

CREATE TABLE "graphql"."coloc_annotation" (
  "coloc_job_id" uuid NOT NULL, 
  "ion_id" integer NOT NULL, 
  "coloc_ion_ids" integer array NOT NULL, 
  "coloc_coeffs" real array NOT NULL, 
  CONSTRAINT "PK_53ff928ca335442ba7b20bcbdbf" PRIMARY KEY ("coloc_job_id", 
  "ion_id")
);

CREATE TABLE "graphql"."ion" (
  "id" SERIAL NOT NULL, 
  "ion" text NOT NULL, 
  "formula" text NOT NULL, 
  "chem_mod" text NOT NULL DEFAULT '', 
  "neutral_loss" text NOT NULL DEFAULT '', 
  "adduct" text NOT NULL, 
  "ion_formula" text NOT NULL DEFAULT '', 
  "charge" smallint NOT NULL, 
  CONSTRAINT "PK_1db9e1ff3fe298cf8a50dad80b5" PRIMARY KEY ("id")
);

CREATE INDEX "IDX_38898b2e9fc8e27fee0d34c164" ON "graphql"."ion" (
  "ion"
) ;

CREATE UNIQUE INDEX "IDX_f538e62b7f815edf1a79aa1ee5" ON "graphql"."ion" (
  "formula", 
  "chem_mod", 
  "neutral_loss", 
  "adduct", 
  "charge"
) ;

CREATE TABLE "public"."dataset" (
  "id" text NOT NULL, 
  "name" text, 
  "input_path" text, 
  "metadata" json, 
  "config" json, 
  "upload_dt" TIMESTAMP, 
  "status" text, 
  "status_update_dt" TIMESTAMP NOT NULL, 
  "optical_image" text, 
  "transform" double precision array, 
  "is_public" boolean NOT NULL DEFAULT true, 
  "acq_geometry" json, 
  "ion_img_storage_type" text NOT NULL DEFAULT 'fs', 
  "thumbnail" text, 
  "thumbnail_url" text, 
  "ion_thumbnail" text, 
  "ion_thumbnail_url" text, 
  CONSTRAINT "PK_1368c0f3639e45c45be6288a232" PRIMARY KEY ("id")
);

CREATE INDEX "ind_dataset_name" ON "public"."dataset" (
  "name"
) ;

CREATE TABLE "public"."optical_image" (
  "id" text NOT NULL, 
  "ds_id" text NOT NULL, 
  "type" text NOT NULL, 
  "zoom" real NOT NULL, 
  "width" integer NOT NULL, 
  "height" integer NOT NULL, 
  "transform" real array, 
  "url" text, 
  CONSTRAINT "PK_4793baa152f99f1ad74856aa7b1" PRIMARY KEY ("id")
);

CREATE TABLE "public"."job" (
  "id" SERIAL NOT NULL, 
  "moldb_id" integer NOT NULL, 
  "ds_id" text, 
  "status" text, 
  "start" TIMESTAMP, 
  "finish" TIMESTAMP, 
  CONSTRAINT "PK_456bc75d32d741774ab85e6606a" PRIMARY KEY ("id")
);

CREATE TABLE "public"."annotation" (
  "id" SERIAL NOT NULL, 
  "job_id" integer NOT NULL, 
  "formula" text NOT NULL, 
  "chem_mod" text NOT NULL, 
  "neutral_loss" text NOT NULL, 
  "adduct" text NOT NULL, 
  "msm" real NOT NULL, 
  "fdr" real NOT NULL, 
  "stats" json NOT NULL, 
  "iso_image_ids" text array NOT NULL, 
  "off_sample" json, 
  "ion_id" integer, 
  CONSTRAINT "annotation_annotation_uindex" UNIQUE ("job_id", 
  "formula", 
  "chem_mod", 
  "neutral_loss", 
  "adduct"), 
  CONSTRAINT "PK_08d866de448fc977523c0e856e5" PRIMARY KEY ("id")
);

CREATE INDEX "annotation_job_id_index" ON "public"."annotation" (
  "job_id"
) ;

CREATE TABLE "public"."perf_profile" (
  "id" SERIAL NOT NULL, 
  "task_type" text NOT NULL, 
  "ds_id" text, 
  "start" TIMESTAMP NOT NULL, 
  "finish" TIMESTAMP, 
  "extra_data" json, 
  "logs" text, 
  "error" text, 
  CONSTRAINT "PK_a180e81bc8817e395daf8a5f8ef" PRIMARY KEY ("id")
);

CREATE TABLE "public"."perf_profile_entry" (
  "id" SERIAL NOT NULL, 
  "profile_id" integer NOT NULL, 
  "sequence" integer NOT NULL, 
  "start" TIMESTAMP NOT NULL, 
  "finish" TIMESTAMP NOT NULL, 
  "name" text NOT NULL, 
  "extra_data" json, 
  CONSTRAINT "PK_729ef8c877e7facd61d75e754e9" PRIMARY KEY ("id")
);

CREATE TABLE "graphql"."image_viewer_snapshot" (
  "id" text NOT NULL, 
  "dataset_id" text NOT NULL, 
  "snapshot" text NOT NULL, 
  "annotation_ids" json NOT NULL, 
  "version" integer NOT NULL, 
  "user_id" uuid, 
  "created_dt" TIMESTAMP NOT NULL, 
  CONSTRAINT "PK_afd32494a70db23e295d94436d7" PRIMARY KEY ("id", 
  "dataset_id")
);

ALTER TABLE "public"."molecular_db" ADD CONSTRAINT "FK_a18f5f7d6cc662006d9c849ea1f" FOREIGN KEY (
  "group_id") REFERENCES "graphql"."group"("id"
) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "public"."molecule" ADD CONSTRAINT "FK_01280507c3bd02500e2861fb279" FOREIGN KEY (
  "moldb_id") REFERENCES "public"."molecular_db"("id"
) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "graphql"."user_group" ADD CONSTRAINT "FK_24850e25a096ba62e57cf5caf45" FOREIGN KEY (
  "user_id") REFERENCES "graphql"."user"("id"
) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "graphql"."user_group" ADD CONSTRAINT "FK_3c213a8a5e3ac56e0882320af43" FOREIGN KEY (
  "group_id") REFERENCES "graphql"."group"("id"
) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "graphql"."user_project" ADD CONSTRAINT "FK_c103849dd5047c315a8bf3d0a71" FOREIGN KEY (
  "user_id") REFERENCES "graphql"."user"("id"
) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "graphql"."user_project" ADD CONSTRAINT "FK_d99bb7781b0c98876331d19387c" FOREIGN KEY (
  "project_id") REFERENCES "graphql"."project"("id"
) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "graphql"."dataset" ADD CONSTRAINT "FK_d890658f7d5c8961e0a0cbdbe41" FOREIGN KEY (
  "user_id") REFERENCES "graphql"."user"("id"
) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "graphql"."dataset" ADD CONSTRAINT "FK_9e18e306ae85131c312e538ca1d" FOREIGN KEY (
  "group_id") REFERENCES "graphql"."group"("id"
) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "graphql"."dataset_project" ADD CONSTRAINT "FK_8bb698a02c945dc2a67a2be2e35" FOREIGN KEY (
  "dataset_id") REFERENCES "graphql"."dataset"("id"
) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "graphql"."dataset_project" ADD CONSTRAINT "FK_e192464449c2ac136fd4f00b439" FOREIGN KEY (
  "project_id") REFERENCES "graphql"."project"("id"
) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "graphql"."user" ADD CONSTRAINT "FK_1b5eb1327a74d679537bdc1fa5b" FOREIGN KEY (
  "credentials_id") REFERENCES "graphql"."credentials"("id"
) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "graphql"."coloc_job" ADD CONSTRAINT "FK_b0adf5ffef6529f187f48231e38" FOREIGN KEY (
  "moldb_id") REFERENCES "public"."molecular_db"("id"
) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "graphql"."coloc_annotation" ADD CONSTRAINT "FK_09673424d3aceab89f931b9f20d" FOREIGN KEY (
  "coloc_job_id") REFERENCES "graphql"."coloc_job"("id"
) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "public"."optical_image" ADD CONSTRAINT "FK_124906daa616c8e1b88645baef0" FOREIGN KEY (
  "ds_id") REFERENCES "public"."dataset"("id"
) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "public"."job" ADD CONSTRAINT "FK_f6baae98b3a2436b6f98318d5d0" FOREIGN KEY (
  "ds_id") REFERENCES "public"."dataset"("id"
) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "public"."job" ADD CONSTRAINT "FK_07f17ed55cabe0ef556bc0e0c93" FOREIGN KEY (
  "moldb_id") REFERENCES "public"."molecular_db"("id"
) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "public"."annotation" ADD CONSTRAINT "FK_bfed30991918671d59fc1f5d5e4" FOREIGN KEY (
  "job_id") REFERENCES "public"."job"("id"
) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "public"."annotation" ADD CONSTRAINT "FK_665acc421d80b12a4738e4a175d" FOREIGN KEY (
  "ion_id") REFERENCES "graphql"."ion"("id"
) ON DELETE SET NULL ON UPDATE NO ACTION;

ALTER TABLE "public"."perf_profile" ADD CONSTRAINT "FK_cea05d4819bacc949a4236b4a8d" FOREIGN KEY (
  "ds_id") REFERENCES "public"."dataset"("id"
) ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "public"."perf_profile_entry" ADD CONSTRAINT "FK_67cf1a415a181173f111690c70a" FOREIGN KEY (
  "profile_id") REFERENCES "public"."perf_profile"("id"
) ON DELETE CASCADE ON UPDATE NO ACTION;


