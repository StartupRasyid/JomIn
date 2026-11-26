CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "analytics_action" AS ENUM ('view', 'like', 'comment', 'save', 'share', 'sticker_click');

-- CreateEnum
CREATE TYPE "application_status" AS ENUM ('pending', 'accepted', 'rejected');

-- CreateEnum
CREATE TYPE "committee_unit" AS ENUM ('Activity', 'Multimedia', 'Food', 'Technical', 'Protocol', 'Sponsorship');

-- CreateEnum
CREATE TYPE "media_type_enum" AS ENUM ('image', 'video');

-- CreateEnum
CREATE TYPE "sticker_type" AS ENUM ('registration_link', 'speaker_bio', 'product_link', 'info_popup');

-- CreateEnum
CREATE TYPE "user_role" AS ENUM ('student', 'organizer', 'admin');

-- CreateTable
CREATE TABLE "ai_chat_messages" (
    "message_id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "session_id" UUID NOT NULL,
    "sender" VARCHAR(10),
    "message_text" TEXT NOT NULL,
    "recommended_event_ids" UUID[],
    "recommended_units" "committee_unit"[],
    "timestamp" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_chat_messages_pkey" PRIMARY KEY ("message_id")
);

-- CreateTable
CREATE TABLE "ai_chat_sessions" (
    "session_id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "user_id" UUID NOT NULL,
    "started_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "ended_at" TIMESTAMPTZ(6),

    CONSTRAINT "ai_chat_sessions_pkey" PRIMARY KEY ("session_id")
);

-- CreateTable
CREATE TABLE "committee_applications" (
    "application_id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "opening_id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "status" "application_status" DEFAULT 'pending',
    "applied_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "committee_applications_pkey" PRIMARY KEY ("application_id")
);

-- CreateTable
CREATE TABLE "committee_openings" (
    "opening_id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "event_id" UUID NOT NULL,
    "unit_name" "committee_unit" NOT NULL,
    "description" TEXT,
    "slots_available" INTEGER DEFAULT 1,
    "is_open" BOOLEAN DEFAULT true,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "committee_openings_pkey" PRIMARY KEY ("opening_id")
);

-- CreateTable
CREATE TABLE "event_analytics_logs" (
    "log_id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "event_id" UUID NOT NULL,
    "user_id" UUID,
    "sticker_id" UUID,
    "action_type" "analytics_action" NOT NULL,
    "timestamp" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "event_analytics_logs_pkey" PRIMARY KEY ("log_id")
);

-- CreateTable
CREATE TABLE "event_comments" (
    "comment_id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "event_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "content" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "event_comments_pkey" PRIMARY KEY ("comment_id")
);

-- CreateTable
CREATE TABLE "event_interests" (
    "event_id" UUID NOT NULL,
    "interest_id" UUID NOT NULL,

    CONSTRAINT "event_interests_pkey" PRIMARY KEY ("event_id","interest_id")
);

-- CreateTable
CREATE TABLE "event_likes" (
    "user_id" UUID NOT NULL,
    "event_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "event_likes_pkey" PRIMARY KEY ("user_id","event_id")
);

-- CreateTable
CREATE TABLE "event_stickers" (
    "sticker_id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "event_id" UUID NOT NULL,
    "type" "sticker_type" NOT NULL,
    "label" VARCHAR(100) NOT NULL,
    "target_url" TEXT,
    "popup_content" TEXT,
    "pos_x" DOUBLE PRECISION,
    "pos_y" DOUBLE PRECISION,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "event_stickers_pkey" PRIMARY KEY ("sticker_id")
);

-- CreateTable
CREATE TABLE "event_wishlists" (
    "user_id" UUID NOT NULL,
    "event_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "event_wishlists_pkey" PRIMARY KEY ("user_id","event_id")
);

-- CreateTable
CREATE TABLE "events" (
    "event_id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "organizer_id" UUID NOT NULL,
    "title" VARCHAR(150) NOT NULL,
    "description" TEXT NOT NULL,
    "media_url" TEXT NOT NULL,
    "media_type" "media_type_enum" DEFAULT 'image',
    "template_id" VARCHAR(50),
    "location" VARCHAR(150),
    "start_time" TIMESTAMPTZ(6) NOT NULL,
    "end_time" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "events_pkey" PRIMARY KEY ("event_id")
);

-- CreateTable
CREATE TABLE "interests" (
    "interest_id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "name" VARCHAR(50) NOT NULL,

    CONSTRAINT "interests_pkey" PRIMARY KEY ("interest_id")
);

-- CreateTable
CREATE TABLE "student_interests" (
    "user_id" UUID NOT NULL,
    "interest_id" UUID NOT NULL,

    CONSTRAINT "student_interests_pkey" PRIMARY KEY ("user_id","interest_id")
);

-- CreateTable
CREATE TABLE "student_profiles" (
    "profile_id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "user_id" UUID NOT NULL,
    "bio" TEXT,
    "personality_summary" TEXT,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "student_profiles_pkey" PRIMARY KEY ("profile_id")
);

-- CreateTable
CREATE TABLE "users" (
    "user_id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "email" VARCHAR(255) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "full_name" VARCHAR(100) NOT NULL,
    "role" "user_role" DEFAULT 'student',
    "faculty" VARCHAR(100),
    "year_of_study" INTEGER,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("user_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "committee_applications_opening_id_student_id_key" ON "committee_applications"("opening_id", "student_id");

-- CreateIndex
CREATE INDEX "idx_committee_openings_event" ON "committee_openings"("event_id");

-- CreateIndex
CREATE INDEX "idx_analytics_event_action" ON "event_analytics_logs"("event_id", "action_type");

-- CreateIndex
CREATE INDEX "idx_events_organizer" ON "events"("organizer_id");

-- CreateIndex
CREATE UNIQUE INDEX "interests_name_key" ON "interests"("name");

-- CreateIndex
CREATE UNIQUE INDEX "student_profiles_user_id_key" ON "student_profiles"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- AddForeignKey
ALTER TABLE "ai_chat_messages" ADD CONSTRAINT "ai_chat_messages_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "ai_chat_sessions"("session_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "ai_chat_sessions" ADD CONSTRAINT "ai_chat_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "committee_applications" ADD CONSTRAINT "committee_applications_opening_id_fkey" FOREIGN KEY ("opening_id") REFERENCES "committee_openings"("opening_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "committee_applications" ADD CONSTRAINT "committee_applications_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "committee_openings" ADD CONSTRAINT "committee_openings_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("event_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_analytics_logs" ADD CONSTRAINT "event_analytics_logs_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("event_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_analytics_logs" ADD CONSTRAINT "event_analytics_logs_sticker_id_fkey" FOREIGN KEY ("sticker_id") REFERENCES "event_stickers"("sticker_id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_analytics_logs" ADD CONSTRAINT "event_analytics_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_comments" ADD CONSTRAINT "event_comments_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("event_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_comments" ADD CONSTRAINT "event_comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_interests" ADD CONSTRAINT "event_interests_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("event_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_interests" ADD CONSTRAINT "event_interests_interest_id_fkey" FOREIGN KEY ("interest_id") REFERENCES "interests"("interest_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_likes" ADD CONSTRAINT "event_likes_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("event_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_likes" ADD CONSTRAINT "event_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_stickers" ADD CONSTRAINT "event_stickers_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("event_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_wishlists" ADD CONSTRAINT "event_wishlists_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("event_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "event_wishlists" ADD CONSTRAINT "event_wishlists_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "events" ADD CONSTRAINT "events_organizer_id_fkey" FOREIGN KEY ("organizer_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "student_interests" ADD CONSTRAINT "student_interests_interest_id_fkey" FOREIGN KEY ("interest_id") REFERENCES "interests"("interest_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "student_interests" ADD CONSTRAINT "student_interests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "student_profiles" ADD CONSTRAINT "student_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

