ALTER TABLE notes ADD CONSTRAINT nonempty_text CHECK (string_nonempty(text));
