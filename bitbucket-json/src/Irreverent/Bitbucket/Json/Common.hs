{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE OverloadedStrings #-}
-------------------------------------------------------------------
-- |
-- Module       : Irreverent.Bitbucket.Json.Common
-- Copyright    : (C) 2017 Irreverent Pixel Feats
-- License      : BSD-style (see the file etc/LICENSE.md)
-- Maintainer   : Dom De Re
--
-------------------------------------------------------------------
module Irreverent.Bitbucket.Json.Common (
  -- * Serialise
    jsonBitbucketTime
  , jsonDisplayName
  , jsonEmailMailingList
  , jsonLanguage
  , jsonHasIssues
  , jsonHasWiki
  , jsonUri
  , jsonHref
  , jsonScm
  , jsonUsername
  , jsonUuid
  , jsonUser
  , jsonUserType
  , jsonForkPolicy
  , jsonPrivacy
  , jsonProjectKey
  , jsonProjectName
  , jsonProject
  , jsonRepoDescription
  , jsonRepoName
  , jsonRepoSlug
  , jsonWebsite
  -- ** Deserialisers
  , parseBitbucketTimeJson
  , parseDisplayNameJson
  , parseEmailMailingListJson
  , parseLanguageJson
  , parseHasIssuesJson
  , parseHasWikiJson
  , parseUriJson
  , parseHrefJson
  , parseScmJson
  , parseUsernameJson
  , parseUuidJson
  , parseUserTypeJson
  , parseUserJson
  , parseForkPolicyJson
  , parsePrivacyJson
  , parseProjectKeyJson
  , parseProjectName
  , parseProjectJson
  , parseRepoDescriptionJson
  , parseRepoName
  , parseRepoSlug
  , parseWebSiteJson
  ) where

-- TODO: explicit export list
import Irreverent.Bitbucket.Core.Data.Common

import Ultra.Data.Aeson (KeyValue, Parser, Object, Value(..), (.=), (.:), (.:?) , object, parseJSON, toJSON)
import qualified Ultra.Data.Text as T

import Data.Time.ISO8601 (formatISO8601, parseISO8601)

import Preamble

jsonBitbucketTime :: BitbucketTime -> Value
jsonBitbucketTime (BitbucketTime t) = toJSON . formatISO8601 $ t

parseBitbucketTimeJson :: Value -> Parser BitbucketTime
parseBitbucketTimeJson v = parseJSON v >>=
  maybe (fail "expected ISO8601 time") (pure . BitbucketTime) . parseISO8601 . T.unpack

jsonDisplayName :: DisplayName -> Value
jsonDisplayName (DisplayName n) = toJSON n

parseDisplayNameJson :: Value -> Parser DisplayName
parseDisplayNameJson v = DisplayName <$> parseJSON v

jsonEmailMailingList :: EmailMailingList -> Value
jsonEmailMailingList (EmailMailingList mailList) = toJSON mailList

parseEmailMailingListJson :: Value -> Parser EmailMailingList
parseEmailMailingListJson v = EmailMailingList <$> parseJSON v

jsonLanguage :: Language -> Value
jsonLanguage (Language l) = toJSON l

parseLanguageJson :: Value -> Parser Language
parseLanguageJson v = Language <$> parseJSON v

jsonHasIssues :: HasIssues -> Value
jsonHasIssues HasIssues = toJSON True
jsonHasIssues NoIssues = toJSON False

parseHasIssuesJson :: Value -> Parser HasIssues
parseHasIssuesJson v = flip fmap (parseJSON v) $ \case
  True  -> HasIssues
  False -> NoIssues

jsonHasWiki :: HasWiki -> Value
jsonHasWiki HasWiki = toJSON True
jsonHasWiki NoWiki  = toJSON False

parseHasWikiJson :: Value -> Parser HasWiki
parseHasWikiJson v = flip fmap (parseJSON v) $ \case
  True  -> HasWiki
  False -> NoWiki

jsonUri :: Uri -> Value
jsonUri (Uri uri) = toJSON uri

parseUriJson :: Value -> Parser Uri
parseUriJson v = Uri <$> parseJSON v

jsonHref :: Href -> Value
jsonHref (Href name url) =
  let
    base :: (KeyValue a) => [a]
    base = pure $ "href" .= jsonUri url
  in object . maybe id (\n -> (:) ("name" .= n)) name $ base

parseHrefJson :: Object -> Parser Href
parseHrefJson o = Href
  <$> o .:? "name"
  <*> (o .: "href" >>= parseUriJson)

jsonScm :: Scm -> Value
jsonScm scm = toJSON $ case scm of
  Git       -> "git" :: T.Text
  Mercurial -> "hg"

parseScmJson :: Value -> Parser Scm
parseScmJson = jsonTextEnum [("git", Git), ("hg", Mercurial)]

jsonUsername :: Username -> Value
jsonUsername (Username n) = toJSON n

parseUsernameJson :: Value -> Parser Username
parseUsernameJson v = Username <$> parseJSON v

jsonUuid :: Uuid -> Value
jsonUuid (Uuid u) = toJSON u

parseUuidJson :: Value -> Parser Uuid
parseUuidJson v = Uuid <$> parseJSON v

jsonUserType :: UserType -> Value
jsonUserType typ = toJSON $ case typ of
  TeamUserType -> "team" :: T.Text
  UserUserType -> "user"

parseUserTypeJson :: Value -> Parser UserType
parseUserTypeJson = jsonTextEnum [("team", TeamUserType), ("user", UserUserType)]

jsonUser :: User -> Value
jsonUser (User name dname typ uuid avatar html self) = object [
    "links" .= object [
      "avatar" .= jsonHref avatar
    , "html" .= jsonHref html
    , "self" .= jsonHref self
    ]
  , "uuid" .= jsonUuid uuid
  , "type" .= jsonUserType typ
  , "display_name" .= jsonDisplayName dname
  , "username" .= jsonUsername name
  ]

parseUserJson :: Object -> Parser User
parseUserJson o = do
  linksObject <- o .: "links"
  User
    <$> (o .: "username" >>= parseUsernameJson)
    <*> (o .: "display_name" >>= parseDisplayNameJson)
    <*> (o .: "type" >>= parseUserTypeJson)
    <*> (o .: "uuid" >>= parseUuidJson)
    <*> (linksObject .: "avatar" >>= parseHrefJson)
    <*> (linksObject .: "html" >>= parseHrefJson)
    <*> (linksObject .: "self" >>= parseHrefJson)

jsonForkPolicy :: ForkPolicy -> Value
jsonForkPolicy policy = toJSON $ case policy of
  NoForksPolicy       -> "no_forks" :: T.Text
  NoPublicForksPolicy -> "no_public_forks"
  ForkAwayPolicy      -> "allow_forks"

parseForkPolicyJson :: Value -> Parser ForkPolicy
parseForkPolicyJson = jsonTextEnum [
    ("no_forks", NoForksPolicy)
  , ("no_public_forks", NoPublicForksPolicy)
  , ("allow_forks", ForkAwayPolicy)
  ]

jsonPrivacy :: Privacy -> Value
jsonPrivacy p = toJSON $ case p of
  Private -> True
  Public  -> False

parsePrivacyJson :: Value -> Parser Privacy
parsePrivacyJson v = flip fmap (parseJSON v) $ \case
  True  -> Private
  False -> Public

jsonProjectKey :: ProjectKey -> Value
jsonProjectKey (ProjectKey key) = toJSON key

parseProjectKeyJson :: Value -> Parser ProjectKey
parseProjectKeyJson v = ProjectKey <$> parseJSON v

jsonProjectName :: ProjectName -> Value
jsonProjectName (ProjectName name) = toJSON name

parseProjectName :: Value -> Parser ProjectName
parseProjectName v = ProjectName <$> parseJSON v

jsonProject :: Project -> Value
jsonProject (Project name uuid key avatar html self) = object [
    "links" .= object [
        "avatar" .= jsonHref avatar
      , "html"   .= jsonHref html
      , "self"   .= jsonHref self
      ]
  , "name"  .= jsonProjectName name
  , "uuid"  .= jsonUuid uuid
  , "type"  .= ("project" :: T.Text)
  , "key"   .= jsonProjectKey key
  ]

parseProjectJson :: Object -> Parser Project
parseProjectJson o = do
  linksObject <- o .: "links"
  o .: "type" >>= jsonTextEnum [("project", ())]
  Project
    <$> (o .: "name" >>= parseProjectName)
    <*> (o .: "uuid" >>= parseUuidJson)
    <*> (o .: "key" >>= parseProjectKeyJson)
    <*> (linksObject .: "avatar" >>= parseHrefJson)
    <*> (linksObject .: "html" >>= parseHrefJson)
    <*> (linksObject .: "self" >>= parseHrefJson)

jsonRepoDescription :: RepoDescription -> Value
jsonRepoDescription (RepoDescription desc) = toJSON desc

parseRepoDescriptionJson :: Value -> Parser RepoDescription
parseRepoDescriptionJson v = RepoDescription <$> parseJSON v

jsonRepoName :: RepoName -> Value
jsonRepoName (RepoName repoName) = toJSON repoName

parseRepoName :: Value -> Parser RepoName
parseRepoName v = RepoName <$> parseJSON v

jsonRepoSlug :: RepoSlug -> Value
jsonRepoSlug (RepoSlug slug) = toJSON slug

parseRepoSlug :: Value -> Parser RepoSlug
parseRepoSlug v = RepoSlug <$> parseJSON v

jsonWebsite :: Website -> Value
jsonWebsite (Website website) = toJSON website

parseWebSiteJson :: Value -> Parser Website
parseWebSiteJson v = Website <$> parseJSON v

-- helpers

-- this should go in ultra-aeson

jsonTextEnum :: NonEmpty (T.Text, a) -> Value -> Parser a
jsonTextEnum cases v =
  let
    errorText :: T.Text -> T.Text
    errorText found = T.bracketedList "expected one of ['" (T.concat ["'], but found: '", found, "'"]) "', '" . toList . fmap fst $ cases
  in do
    t <- parseJSON v
    foldr
      (\(t', x) p -> if (t == t') then pure x else p)
      (fail . T.unpack . errorText $ t)
      cases