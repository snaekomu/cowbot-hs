{-# LANGUAGE OverloadedStrings #-}

module Translate ( translate
                 , langTypes
                 , langNames
                 ) where

import           Data.Map                as M
import qualified Data.Text               as T

import           Network.HTTP.Client
import           Network.HTTP.Client.TLS
import           Network.HTTP.Req
import           Web.Google.Translate    (Body (Body), Key (Key), Lang (..),
                                          Source, Target,
                                          TranslatedText (TranslatedText),
                                          Translation (detectedSourceLanguage, translatedText),
                                          TranslationResponse (translations))
import qualified Web.Google.Translate    as Trans (translate)

import           UnliftIO

import           Secrets                 (tr_key)

manager :: IO Manager
manager = newTlsManager

translate :: T.Text -> Maybe Source -> Target -> IO (Maybe (T.Text, Maybe T.Text))
translate b s t = do
    k <- Key <$> Secrets.tr_key
    m <- manager
    -------------------

    transResult <- Trans.translate m k s t $ Body b

    t <- return $ do
        res <- transResult
        let trans = head $ translations res
            f     = T.pack . show <$> detectedSourceLanguage trans
            t     = (\(TranslatedText t) -> t) $ translatedText trans
        return (t, f)

    case t of Right (text, mLang) -> return $ Just (text, mLang)
              Left _              -> return Nothing

langNames :: M.Map T.Text T.Text
langNames = M.fromList [ ("af", "Afrikaans")
                    , ("sq", "Albanian")
                    , ("ar", "Arabic")
                    , ("hy", "Armenian")
                    , ("az", "Azerbaijani")
                    , ("eu", "Basque")
                    , ("be", "Belarusian")
                    , ("bn", "Bengali")
                    , ("bs", "Bosnian")
                    , ("bg", "Bulgarian")
                    , ("ca", "Catalan")
                    , ("ceb", "Cebuano")
                    , ("ny", "Chichewa")
                    , ("zh", "ChineseSimplified")
                    , ("zh-TW", "ChineseTraditional")
                    , ("hr", "Croatian")
                    , ("cs", "Czech")
                    , ("da", "Danish")
                    , ("nl", "Dutch")
                    , ("en", "English")
                    , ("eo", "Esperanto")
                    , ("et", "Estonian")
                    , ("tl", "Filipino")
                    , ("fi", "Finnish")
                    , ("fr", "French")
                    , ("gl", "Galician")
                    , ("ka", "Georgian")
                    , ("de", "German")
                    , ("el", "Greek")
                    , ("gu", "Gujarati")
                    , ("ht", "HaitianCreole")
                    , ("ha", "Hausa")
                    , ("iw", "Hebrew")
                    , ("hi", "Hindi")
                    , ("hmn", "Hmong")
                    , ("hu", "Hungarian")
                    , ("is", "Icelandic")
                    , ("ig", "Igbo")
                    , ("id", "Indonesian")
                    , ("ga", "Irish")
                    , ("it", "Italian")
                    , ("ja", "Japanese")
                    , ("jw", "Javanese")
                    , ("kn", "Kannada")
                    , ("kk", "Kazakh")
                    , ("km", "Khmer")
                    , ("ko", "Korean")
                    , ("lo", "Lao")
                    , ("la", "Latin")
                    , ("lv", "Latvian")
                    , ("lt", "Lithuanian")
                    , ("mk", "Macedonian")
                    , ("mg", "Malagasy")
                    , ("ms", "Malay")
                    , ("ml", "Malayalam")
                    , ("mt", "Maltese")
                    , ("mi", "Maori")
                    , ("mr", "Marathi")
                    , ("mn", "Mongolian")
                    , ("my", "MyanmarBurmese")
                    , ("ne", "Nepali")
                    , ("no", "Norwegian")
                    , ("fa", "Persian")
                    , ("pl", "Polish")
                    , ("pt", "Portuguese")
                    , ("pa", "Punjabi")
                    , ("ro", "Romanian")
                    , ("ru", "Russian")
                    , ("sr", "Serbian")
                    , ("st", "Sesotho")
                    , ("si", "Sinhala")
                    , ("sk", "Slovak")
                    , ("sl", "Slovenian")
                    , ("so", "Somali")
                    , ("es", "Spanish")
                    , ("su", "Sundanese")
                    , ("sw", "Swahili")
                    , ("sv", "Swedish")
                    , ("tg", "Tajik")
                    , ("ta", "Tamil")
                    , ("te", "Telugu")
                    , ("th", "Thai")
                    , ("tr", "Turkish")
                    , ("uk", "Ukrainian")
                    , ("ur", "Urdu")
                    , ("uz", "Uzbek")
                    , ("vi", "Vietnamese")
                    , ("cy", "Welsh")
                    , ("yi", "Yiddish")
                    , ("yo", "Yoruba")
                    , ("zu", "Zulu")
                    ]

langTypes :: [ Lang ]
langTypes = [ Afrikaans
            , Albanian
            , Arabic
            , Armenian
            , Azerbaijani
            , Basque
            , Belarusian
            , Bengali
            , Bosnian
            , Bulgarian
            , Catalan
            , Cebuano
            , Chichewa
            , ChineseSimplified
            , ChineseTraditional
            , Croatian
            , Czech
            , Danish
            , Dutch
            , English
            , Esperanto
            , Estonian
            , Filipino
            , Finnish
            , French
            , Galician
            , Georgian
            , German
            , Greek
            , Gujarati
            , HaitianCreole
            , Hausa
            , Hebrew
            , Hindi
            , Hmong
            , Hungarian
            , Icelandic
            , Igbo
            , Indonesian
            , Irish
            , Italian
            , Japanese
            , Javanese
            , Kannada
            , Kazakh
            , Khmer
            , Korean
            , Lao
            , Latin
            , Latvian
            , Lithuanian
            , Macedonian
            , Malagasy
            , Malay
            , Malayalam
            , Maltese
            , Maori
            , Marathi
            , Mongolian
            , MyanmarBurmese
            , Nepali
            , Norwegian
            , Persian
            , Polish
            , Portuguese
            , Punjabi
            , Romanian
            , Russian
            , Serbian
            , Sesotho
            , Sinhala
            , Slovak
            , Slovenian
            , Somali
            , Spanish
            , Sundanese
            , Swahili
            , Swedish
            , Tajik
            , Tamil
            , Telugu
            , Thai
            , Turkish
            , Ukrainian
            , Urdu
            , Uzbek
            , Vietnamese
            , Welsh
            , Yiddish
            , Yoruba
            , Zulu
            ]
