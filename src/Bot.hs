{-# LANGUAGE MultiWayIf #-}
module Bot (runBot) where

import           Commands
import           Control.Applicative  (Alternative (empty))
import           Control.Monad        (forM_, guard, when)
import           Data.Text            (pack)
import qualified Data.Text            as T
import qualified Data.Text.IO         as TIO
import           Discord              (DiscordHandler,
                                       RunDiscordOpts (discordOnEnd, discordOnEvent, discordOnLog, discordOnStart, discordToken),
                                       def, restCall, runDiscord)
import qualified Discord.Requests     as R
import           Discord.Types        (Channel (ChannelText, channelId),
                                       Event (MessageCreate, MessageReactionAdd),
                                       Guild (guildId),
                                       Message (messageAuthor, messageText),
                                       PartialGuild (partialGuildId),
                                       User (userIsBot), emojiName,
                                       reactionChannelId, reactionEmoji,
                                       reactionMessageId)
import           Parser.Parser        (Parser (..), alias, prefix)
import           Reactions            (reactTranslate)
import           Secrets              (token)
import           Types
import           Types.Discord        (Command, Reaction, interpret)
import           UnliftIO             (liftIO)
import           UnliftIO.Concurrent  (threadDelay)
import           Web.Google.Translate (Lang (English))


runBot :: IO ()
runBot = do
  tok <- token
  -- open ghci and run  [[ :info RunDiscordOpts ]] to see available fields
  t <- runDiscord $ def { discordToken = tok
                        , discordOnStart = liftIO $ putStrLn "Started"
                        , discordOnEnd = liftIO $ putStrLn "Ended"
                        , discordOnEvent = eventHandler
                        , discordOnLog = \s -> TIO.putStrLn s >> TIO.putStrLn ""
                        }
  threadDelay (1 `div` 10 * 10^(6 :: Int))
  TIO.putStrLn t

-- If the start handler throws an exception, discord-haskell will gracefully shutdown
--     Use place to execute commands you know you want to complete
startHandler :: DiscordHandler ()
startHandler = do
  Right partialGuilds <- restCall R.GetCurrentUserGuilds

  forM_ partialGuilds $ \pg -> do
    Right guild <- restCall $ R.GetGuild (partialGuildId pg)
    Right chans <- restCall $ R.GetGuildChannels (guildId guild)
    case filter isTextChannel chans of
      (c:_) -> do _ <- restCall $ R.CreateMessage (channelId c) "Hello! I will reply to pings with pongs"
                  pure ()
      _ -> pure ()

-- If an event handler throws an exception, discord-haskell will continue to run
eventHandler :: Event -> DiscordHandler ()
eventHandler event = case event of
      MessageCreate m ->
        when (not $ fromBot m) $ interpret m messageText commandSwitch

      MessageReactionAdd r -> interpret r (const "") reactionSwitch
      _ -> pure ()

isTextChannel :: Channel -> Bool
isTextChannel (ChannelText {}) = True
isTextChannel _                = False

fromBot :: Message -> Bool
fromBot = userIsBot . messageAuthor

commandSwitch :: Command ()
commandSwitch = do
    parse prefix >>= extract
    a <- parse alias  >>= extract
    if
        | a == "clap"  -> clap
        | a == "bless" -> bless
        | a == "t"     -> comTranslate
        | a == "yt"    -> yt
        | otherwise    -> return ()

    where extract (Just x) = pure x
          extract Nothing  = empty

reactionSwitch :: Reaction ()
reactionSwitch = do
    mid <- askReaction reactionMessageId
    cid <- askReaction reactionChannelId
    em  <- askReaction $ emojiName . reactionEmoji
    amt <- dis $ do
            em <- restCall $ R.GetReactions (cid, mid) em (2, R.BeforeReaction mid)
            case em of Right m -> return $ m
                       _       -> return []

    guard (length amt <= 1)

    let is e = T.head e == T.head em
    if
        | is "🔣"    -> reactTranslate $ Just English
        | is "🗺"    -> reactTranslate Nothing
        | otherwise -> pure ()

    return ()
