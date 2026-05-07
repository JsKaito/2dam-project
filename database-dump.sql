


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."delete_user_account"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;


ALTER FUNCTION "public"."delete_user_account"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_connections"("target_id" "uuid", "conn_type" "text", "viewer_id" "uuid") RETURNS TABLE("id" "uuid", "username" "text", "display_name" "text", "avatar_url" "text", "is_verified" boolean, "is_mutual" boolean, "viewer_is_following" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id, 
        p.username, 
        p.display_name, 
        p.avatar_url, 
        p.is_verified,
        ((EXISTS (
            SELECT 1 FROM followers f1 
            WHERE f1.follower_id = viewer_id AND f1.following_id = p.id
        )) AND (EXISTS (
            SELECT 1 FROM followers f2 
            WHERE f2.follower_id = p.id AND f2.following_id = viewer_id
        ))) as is_mutual,
        EXISTS (
            SELECT 1 FROM followers f3 
            WHERE f3.follower_id = viewer_id AND f3.following_id = p.id
        ) as viewer_is_following
    FROM profiles p
    JOIN followers f ON (
        CASE 
            WHEN conn_type = 'followers' THEN f.follower_id = p.id 
            ELSE f.following_id = p.id 
        END
    )
    WHERE (
        CASE 
            WHEN conn_type = 'followers' THEN f.following_id = target_id 
            ELSE f.follower_id = target_id 
        END
    )
    ORDER BY is_mutual DESC, p.username ASC;
END;
$$;


ALTER FUNCTION "public"."get_user_connections"("target_id" "uuid", "conn_type" "text", "viewer_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_follow_notification"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  INSERT INTO notifications (receiver_id, sender_id, type)
  VALUES (NEW.following_id, NEW.follower_id, 'follow');
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_follow_notification"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_notification"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    target_user_id UUID;
    actual_sender_id UUID;
    actual_post_id BIGINT;
    notification_type TEXT;
    is_enabled BOOLEAN;
BEGIN
    IF (TG_TABLE_NAME = 'post_likes') THEN
        target_user_id := (SELECT user_id FROM public.posts WHERE id = NEW.post_id);
        actual_sender_id := NEW.user_id;
        actual_post_id := NEW.post_id;
        notification_type := 'like';
        SELECT push_likes INTO is_enabled FROM public.profiles WHERE id = target_user_id;

    ELSIF (TG_TABLE_NAME = 'comments') THEN
        actual_sender_id := NEW.user_id;
        actual_post_id := NEW.post_id;
        IF (NEW.parent_id IS NULL) THEN
            target_user_id := (SELECT user_id FROM public.posts WHERE id = NEW.post_id);
            notification_type := 'comment';
            SELECT push_comments INTO is_enabled FROM public.profiles WHERE id = target_user_id;
        ELSE
            target_user_id := (SELECT user_id FROM public.comments WHERE id = NEW.parent_id);
            notification_type := 'reply';
            SELECT push_mentions INTO is_enabled FROM public.profiles WHERE id = target_user_id;
        END IF;

    ELSIF (TG_TABLE_NAME = 'followers') THEN
        target_user_id := NEW.following_id;
        actual_sender_id := NEW.follower_id;
        actual_post_id := NULL;
        notification_type := 'follow';
        SELECT push_followers INTO is_enabled FROM public.profiles WHERE id = target_user_id;
    END IF;

    IF (target_user_id IS NULL OR actual_sender_id = target_user_id) THEN 
        RETURN NEW; 
    END IF;

    IF (is_enabled IS NULL OR is_enabled = true) THEN
        INSERT INTO public.notifications (receiver_id, sender_id, type, post_id)
        VALUES (target_user_id, actual_sender_id, notification_type, actual_post_id);
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_notification"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, avatar_url)
  VALUES (
    new.id, 
    new.raw_user_meta_data->>'username', 
    new.raw_user_meta_data->>'username',
    'https://yrbzkgfomjqilmyxzfqe.supabase.co/storage/v1/object/public/default/default_pfp.webp'
  );
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_verification_update"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF (NEW.status = 'accepted') THEN
    UPDATE public.profiles
    SET is_verified = true
    WHERE id = NEW.user_id;
  ELSE
    UPDATE public.profiles
    SET is_verified = false
    WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_verification_update"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."blocked_users" (
    "blocker_id" "uuid" NOT NULL,
    "blocked_id" "uuid" NOT NULL
);


ALTER TABLE "public"."blocked_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."comment_likes" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "comment_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."comment_likes" OWNER TO "postgres";


ALTER TABLE "public"."comment_likes" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."comment_likes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."comments" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "post_id" bigint NOT NULL,
    "content" "text" NOT NULL,
    "parent_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "reply_to_username" "text"
);


ALTER TABLE "public"."comments" OWNER TO "postgres";


ALTER TABLE "public"."comments" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."comments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."follow_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "receiver_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "follow_requests_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."follow_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."followers" (
    "follower_id" "uuid" NOT NULL,
    "following_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."followers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "receiver_id" "uuid",
    "sender_id" "uuid",
    "type" "text" NOT NULL,
    "post_id" bigint,
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."post_likes" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "post_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."post_likes" OWNER TO "postgres";


ALTER TABLE "public"."post_likes" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."post_likes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."posts" (
    "id" bigint NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "content" "text",
    "image_url" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "title" "text",
    "author_name" "text",
    "capture_date" "text"
);


ALTER TABLE "public"."posts" OWNER TO "postgres";


ALTER TABLE "public"."posts" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."posts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "username" "text",
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "bio" "text",
    "display_name" "text",
    "is_private" boolean DEFAULT false,
    "push_likes" boolean DEFAULT true,
    "push_comments" boolean DEFAULT true,
    "push_followers" boolean DEFAULT true,
    "push_mentions" boolean DEFAULT true,
    "email_notifications" boolean DEFAULT false,
    "content_filter" boolean DEFAULT true,
    "tag_approval_required" boolean DEFAULT false,
    "who_can_comment" "text" DEFAULT 'everyone'::"text",
    "hidden_words" "text" DEFAULT ''::"text",
    "language" "text" DEFAULT 'es'::"text",
    "mfa_enabled" boolean DEFAULT false,
    "high_quality_enabled" boolean DEFAULT true,
    "is_verified" boolean DEFAULT false,
    "banner_url" "text"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."support_tickets" (
    "id" bigint NOT NULL,
    "user_id" "uuid",
    "type" "text",
    "content" "text",
    "status" "text" DEFAULT 'pending'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."support_tickets" OWNER TO "postgres";


ALTER TABLE "public"."support_tickets" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."support_tickets_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."verification_requests" (
    "id" bigint NOT NULL,
    "user_id" "uuid",
    "status" "text" DEFAULT 'pending'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."verification_requests" OWNER TO "postgres";


ALTER TABLE "public"."verification_requests" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."verification_requests_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."blocked_users"
    ADD CONSTRAINT "blocked_users_pkey" PRIMARY KEY ("blocker_id", "blocked_id");



ALTER TABLE ONLY "public"."comment_likes"
    ADD CONSTRAINT "comment_likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comment_likes"
    ADD CONSTRAINT "comment_likes_user_id_comment_id_key" UNIQUE ("user_id", "comment_id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."follow_requests"
    ADD CONSTRAINT "follow_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."follow_requests"
    ADD CONSTRAINT "follow_requests_sender_id_receiver_id_key" UNIQUE ("sender_id", "receiver_id");



ALTER TABLE ONLY "public"."followers"
    ADD CONSTRAINT "followers_pkey" PRIMARY KEY ("follower_id", "following_id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_likes"
    ADD CONSTRAINT "post_likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_likes"
    ADD CONSTRAINT "post_likes_user_id_post_id_key" UNIQUE ("user_id", "post_id");



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."support_tickets"
    ADD CONSTRAINT "support_tickets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "unique_username" UNIQUE ("username");



ALTER TABLE ONLY "public"."verification_requests"
    ADD CONSTRAINT "verification_requests_pkey" PRIMARY KEY ("id");



CREATE INDEX "profiles_username_idx" ON "public"."profiles" USING "btree" ("username");



CREATE OR REPLACE TRIGGER "on_comment_notification" AFTER INSERT ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_notification"();



CREATE OR REPLACE TRIGGER "on_follow_notification" AFTER INSERT ON "public"."followers" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_notification"();



CREATE OR REPLACE TRIGGER "on_like_notification" AFTER INSERT ON "public"."post_likes" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_notification"();



CREATE OR REPLACE TRIGGER "on_verification_change" AFTER UPDATE ON "public"."verification_requests" FOR EACH ROW EXECUTE FUNCTION "public"."handle_verification_update"();



ALTER TABLE ONLY "public"."blocked_users"
    ADD CONSTRAINT "blocked_users_blocked_id_fkey" FOREIGN KEY ("blocked_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."blocked_users"
    ADD CONSTRAINT "blocked_users_blocker_id_fkey" FOREIGN KEY ("blocker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comment_likes"
    ADD CONSTRAINT "comment_likes_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comment_likes"
    ADD CONSTRAINT "comment_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."follow_requests"
    ADD CONSTRAINT "follow_requests_receiver_id_fkey" FOREIGN KEY ("receiver_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."follow_requests"
    ADD CONSTRAINT "follow_requests_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."followers"
    ADD CONSTRAINT "followers_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."followers"
    ADD CONSTRAINT "followers_following_id_fkey" FOREIGN KEY ("following_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_receiver_id_fkey" FOREIGN KEY ("receiver_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_likes"
    ADD CONSTRAINT "post_likes_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_likes"
    ADD CONSTRAINT "post_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."support_tickets"
    ADD CONSTRAINT "support_tickets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."verification_requests"
    ADD CONSTRAINT "verification_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



CREATE POLICY "Cualquiera puede ver seguidores" ON "public"."followers" FOR SELECT USING (true);



CREATE POLICY "Dejar de seguir" ON "public"."followers" FOR DELETE USING (("auth"."uid"() = "follower_id"));



CREATE POLICY "Followers visibles para todos" ON "public"."followers" FOR SELECT USING (true);



CREATE POLICY "Lectura pública de comentarios" ON "public"."comments" FOR SELECT USING (true);



CREATE POLICY "Lectura pública de likes" ON "public"."post_likes" FOR SELECT USING (true);



CREATE POLICY "Lectura pública de likes de comentarios" ON "public"."comment_likes" FOR SELECT USING (true);



CREATE POLICY "Los usuarios pueden borrar sus propios comentarios" ON "public"."comments" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Perfiles públicos visibles para todos" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Permitir al receptor aceptar el seguimiento" ON "public"."followers" FOR INSERT WITH CHECK (("auth"."uid"() = "following_id"));



CREATE POLICY "Permitir borrar mis propios likes de comentarios" ON "public"."comment_likes" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Permitir borrar mis propios likes de posts" ON "public"."post_likes" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Permitir insertar mis propios likes de comentarios" ON "public"."comment_likes" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Permitir insertar mis propios likes de posts" ON "public"."post_likes" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Permitir lectura de likes de comentarios" ON "public"."comment_likes" FOR SELECT USING (true);



CREATE POLICY "Permitir lectura de likes de posts" ON "public"."post_likes" FOR SELECT USING (true);



CREATE POLICY "Posts visibles para todos" ON "public"."posts" FOR SELECT USING (true);



CREATE POLICY "Seguir" ON "public"."followers" FOR INSERT WITH CHECK (("auth"."uid"() = "follower_id"));



CREATE POLICY "Seguir a otros" ON "public"."followers" FOR INSERT WITH CHECK (("auth"."uid"() = "follower_id"));



CREATE POLICY "Usuarios autenticados pueden crear posts" ON "public"."posts" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Usuarios borran/actualizan sus notificaciones" ON "public"."notifications" USING (("auth"."uid"() = "receiver_id"));



CREATE POLICY "Usuarios pueden borrar sus propios posts" ON "public"."posts" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Usuarios pueden cancelar o el receptor puede rechazar" ON "public"."follow_requests" FOR DELETE USING ((("auth"."uid"() = "sender_id") OR ("auth"."uid"() = "receiver_id")));



CREATE POLICY "Usuarios pueden comentar" ON "public"."comments" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Usuarios pueden dar like" ON "public"."post_likes" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Usuarios pueden dar like a comentarios" ON "public"."comment_likes" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Usuarios pueden dejar de seguir" ON "public"."followers" FOR DELETE USING (("auth"."uid"() = "follower_id"));



CREATE POLICY "Usuarios pueden editar su propio perfil" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Usuarios pueden enviar solicitudes" ON "public"."follow_requests" FOR INSERT WITH CHECK (("auth"."uid"() = "sender_id"));



CREATE POLICY "Usuarios pueden insertar su propio perfil" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Usuarios pueden quitar like" ON "public"."post_likes" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Usuarios pueden seguir" ON "public"."followers" FOR INSERT WITH CHECK (("auth"."uid"() = "follower_id"));



CREATE POLICY "Usuarios pueden seguir a otros" ON "public"."followers" FOR INSERT WITH CHECK (("auth"."uid"() = "follower_id"));



CREATE POLICY "Usuarios pueden ver solicitudes enviadas o recibidas" ON "public"."follow_requests" FOR SELECT USING ((("auth"."uid"() = "sender_id") OR ("auth"."uid"() = "receiver_id")));



CREATE POLICY "Usuarios ven sus propias notificaciones" ON "public"."notifications" FOR SELECT USING (("auth"."uid"() = "receiver_id"));



CREATE POLICY "Ver seguidores" ON "public"."followers" FOR SELECT USING (true);



ALTER TABLE "public"."blocked_users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."comment_likes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."comments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."follow_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."followers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."post_likes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."posts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."support_tickets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."verification_requests" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."follow_requests";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."posts";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."profiles";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































GRANT ALL ON FUNCTION "public"."delete_user_account"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_user_account"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_user_account"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_connections"("target_id" "uuid", "conn_type" "text", "viewer_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_connections"("target_id" "uuid", "conn_type" "text", "viewer_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_connections"("target_id" "uuid", "conn_type" "text", "viewer_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_follow_notification"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_follow_notification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_follow_notification"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_notification"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_notification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_notification"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_verification_update"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_verification_update"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_verification_update"() TO "service_role";


















GRANT ALL ON TABLE "public"."blocked_users" TO "anon";
GRANT ALL ON TABLE "public"."blocked_users" TO "authenticated";
GRANT ALL ON TABLE "public"."blocked_users" TO "service_role";



GRANT ALL ON TABLE "public"."comment_likes" TO "anon";
GRANT ALL ON TABLE "public"."comment_likes" TO "authenticated";
GRANT ALL ON TABLE "public"."comment_likes" TO "service_role";



GRANT ALL ON SEQUENCE "public"."comment_likes_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."comment_likes_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."comment_likes_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."comments" TO "anon";
GRANT ALL ON TABLE "public"."comments" TO "authenticated";
GRANT ALL ON TABLE "public"."comments" TO "service_role";



GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."follow_requests" TO "anon";
GRANT ALL ON TABLE "public"."follow_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."follow_requests" TO "service_role";



GRANT ALL ON TABLE "public"."followers" TO "anon";
GRANT ALL ON TABLE "public"."followers" TO "authenticated";
GRANT ALL ON TABLE "public"."followers" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."post_likes" TO "anon";
GRANT ALL ON TABLE "public"."post_likes" TO "authenticated";
GRANT ALL ON TABLE "public"."post_likes" TO "service_role";



GRANT ALL ON SEQUENCE "public"."post_likes_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."post_likes_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."post_likes_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."posts" TO "anon";
GRANT ALL ON TABLE "public"."posts" TO "authenticated";
GRANT ALL ON TABLE "public"."posts" TO "service_role";



GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."posts_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."support_tickets" TO "anon";
GRANT ALL ON TABLE "public"."support_tickets" TO "authenticated";
GRANT ALL ON TABLE "public"."support_tickets" TO "service_role";



GRANT ALL ON SEQUENCE "public"."support_tickets_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."support_tickets_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."support_tickets_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."verification_requests" TO "anon";
GRANT ALL ON TABLE "public"."verification_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."verification_requests" TO "service_role";



GRANT ALL ON SEQUENCE "public"."verification_requests_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."verification_requests_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."verification_requests_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































