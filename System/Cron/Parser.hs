{-# LANGUAGE OverloadedStrings #-}
module System.Cron.Parser (cronSchedule) where

import System.Cron

import Control.Applicative ((<*>),
                            (*>),
                            (<*),
                            (<$>),
                            (<|>),
                            pure)
import qualified Data.Attoparsec.Text as A
import Data.Attoparsec.Text (Parser)

--TODO: peek first character
cronSchedule :: Parser CronSchedule
cronSchedule = yearlyP  <|>
               monthlyP <|>
               weeklyP  <|>
               dailyP   <|>
               hourlyP  <|>
               classicP

---- Internals

classicP :: Parser CronSchedule
classicP = CronSchedule <$> (minutesP    <* space)
                        <*> (hoursP      <* space)
                        <*> (dayOfMonthP <* space)
                        <*> (monthP      <* space)
                        <*> dayOfWeekP
  where space = A.char ' '

cronFieldP :: Parser CronField
cronFieldP = starP     <|>
             rangeP    <|>
             listP     <|>
             dividedP  <|>
             specificP
  where starP         = A.char '*' *> pure Star
        rangeP        = do start <- parseInt
                           A.char '-'
                           end   <- parseInt
                           if start <= end
                             then return $ Range start end
                             else rangeInvalid
        rangeInvalid  = fail "start of range must be less than or equal to end"
        -- Must avoid infinitely recursive parsers
        listP         = ListField <$> A.sepBy1 listableP (A.char ',')
        listableP     = starP    <|>
                        rangeP   <|>
                        dividedP <|>
                        specificP
        divListP      = ListField <$> A.sepBy1 divListableP (A.char ',')
        divListableP  = starP    <|>
                        rangeP
        dividedP      = DividedField <$> divisibleP <*> (A.char '/' *> parseInt)
        divisibleP    = starP          <|>
                        rangeP         <|>
                        divListP       <|>
                        specificP
        specificP     = SpecificField <$> parseInt

yearlyP :: Parser CronSchedule
yearlyP  = A.string "@yearly"  *> pure yearly

monthlyP :: Parser CronSchedule
monthlyP = A.string "@monthly" *> pure monthly

weeklyP :: Parser CronSchedule
weeklyP  = A.string "@weekly"  *> pure weekly

dailyP :: Parser CronSchedule
dailyP   = A.string "@daily"   *> pure daily

hourlyP :: Parser CronSchedule
hourlyP  = A.string "@hourly"  *> pure hourly


--TODO: must handle a combination of many of these. EITHER just *, OR a list of 
minutesP :: Parser MinuteSpec
minutesP = Minutes <$> cronFieldP

hoursP :: Parser HourSpec
hoursP = Hours <$> cronFieldP

dayOfMonthP :: Parser DayOfMonthSpec
dayOfMonthP = DaysOfMonth <$> cronFieldP

monthP :: Parser MonthSpec
monthP = Months <$> cronFieldP

dayOfWeekP :: Parser DayOfWeekSpec
dayOfWeekP = DaysOfWeek <$> cronFieldP

parseInt :: Parser Int
parseInt = fromIntegral <$> A.decimal
