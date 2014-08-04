package org.pandragon;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;
import org.apache.maven.artifact.versioning.ComparableVersion;

import java.lang.reflect.Field;

public class ComparableVersionTest extends TestCase {
    /**
     * Create the test case
     *
     * @param testName name of the test case
     */
    public ComparableVersionTest( String testName )
    {
        super( testName );
    }

    /**
     * @return the suite of tests being tested
     */
    public static Test suite()
    {
        return new TestSuite( ComparableVersionTest.class );
    }

    public void testNormalization() {
        ComparableVersionNormalizer normalizer = new ComparableVersionNormalizer();
        //test 1
        assertEquals("(1)", normalizer.toString("1.0"));
        //test 2
        assertEquals("(1,0,1)", normalizer.toString("1.0.1"));
        //test 3
        assertEquals("(1,(1))", normalizer.toString("1.0-1"));
        //test 4
        assertEquals("(1,(1,alpha,1))", normalizer.toString("1.0-1-alpha-1"));
        //test 5
        assertEquals("(222,,0,1,,1,(1,rc))", normalizer.toString("222-ga.0.1-final.1-1-rc.final"));
        //test 6
        assertEquals("(1,,1,0,1,(1,(4,snapshot)))", normalizer.toString("1.0-final-1.0.1-1-4-SNAPSHOT"));
        //test 7
        assertEquals("(1,1,(1,1,(1,1,(1,1))))", normalizer.toString("1.1-1.1-1.1-1.1"));
        //test 8
        assertEquals("(1,0,0,0,1)", normalizer.toString("1....1"));
        //test 9
        assertEquals("(milestone,1)", normalizer.toString("m1"));
        //test 10 
        assertEquals("(1,alpha,1)", normalizer.toString("1-a1"));
        //test 11 
        assertEquals("(beta,1)", normalizer.toString("b1"));
        //test 12 
        assertEquals("(1,beta,1)", normalizer.toString("1-b1"));
        //test 13
        assertEquals("(milestone,1)", normalizer.toString("m1"));
        //test 14
        assertEquals("(1,milestone,1)", normalizer.toString("1-m1"));
        //test 15
        assertEquals("(,0,1)", normalizer.toString("final-0.1"));
        //test 16
        assertEquals("()", normalizer.toString("final.0.0"));
        //test 17
        assertEquals("(0,1,0,1)", normalizer.toString("-1-.1"));
        //test 18
        assertEquals("(milestone,1,char)", normalizer.toString("m1char"));
        //test 19
        assertEquals("(milestone,12)", normalizer.toString("m12"));
        //test 20
        assertEquals("(xxx,12)", normalizer.toString("xxx12"));
    }

    public void testListItemsComparisons() {
        ComparableVersionTestor testor = new ComparableVersionTestor();
        //test 1
        assertTrue("1-1.1 < 1.1", testor.compareVersions("1-1.1", "1.1") < 0);

        //test 2
        assertTrue("1-1 < 1.alpha", testor.compareVersions("1-1", "1.alpha") > 0);

        //test 3
        assertTrue("1-0.final.ga == 1", testor.compareVersions("1-0.final.ga", "1") == 0);

        //test 4
        assertTrue("1-0.alpha == 1", testor.compareVersions("1-0.alpha", "1") == 0);

        //test 5
        assertTrue("1-1 > 1", testor.compareVersions("1-1", "1") > 0);

        //test 6
        assertTrue("(alpha) < ()", testor.compareVersions("alpha", "0") < 0);

        //test 7
        assertTrue("1-1-rc-2 > 1-1-rc-1", testor.compareVersions("1-1-rc-2", "1-1-rc-1") > 0);

        //test 8
        assertTrue("1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-alpha > 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-beta",
                testor.compareVersions("1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-alpha", "1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-beta") < 0);
    }

    public void testIntegerItemsComparison() {
        ComparableVersionTestor testor = new ComparableVersionTestor();

        //test 1
        assertTrue("1 < 2", testor.compareVersions("1", "2") < 0);

        //test 2
        assertTrue("2 > 1", testor.compareVersions("2", "1") > 0);

        //test 3
        assertTrue("2 == 2", testor.compareVersions("2", "2") == 0);

        //test 4
        assertTrue("1.1 > 1-m1", testor.compareVersions("1.1", "1-m1") > 0);

        //test 5
        assertTrue("1.1 > 1-1", testor.compareVersions("1.1", "1-1") > 0);

        //test 6
        assertTrue("1.0.1 > 1.ga.1", testor.compareVersions("1.0.1", "1.ga.1") > 0);

        //test 7
        assertTrue("1.0.1 == 1..1", testor.compareVersions("1.0.1", "1..1") == 0);

        //test 8
        assertTrue("0 < sp", testor.compareVersions("0", "sp") < 0);
        
        //test 9
        assertTrue("1-1.0.sp > 1-1-SNAPSHOT", testor.compareVersions("1-1.0.sp", "1-1-SNAPSHOT") > 0);

    }

    public void testStringItemsComparison() {
        ComparableVersionTestor testor = new ComparableVersionTestor();
        //test 1
        assertTrue("1-xxxxx < 1.1", testor.compareVersions("1-xxxxx", "1.1") < 0);
        //test 2
        assertTrue("1-xxxxx < 1-0.1", testor.compareVersions("1-xxxxx", "1-0.1") < 0);
        //test 3
        assertTrue("1-ga == 1", testor.compareVersions("1-ga", "1") == 0);
    }

    public void testQualifiersComparison() {
        ComparableVersionTestor testor = new ComparableVersionTestor();
        //test 1
        assertTrue("alpha < beta", testor.compareVersions("alpha", "beta") < 0);
        //test 2
        assertTrue("beta < milestone", testor.compareVersions("beta", "milestone") < 0);
        //test 3
        assertTrue("milestone < rc", testor.compareVersions("milestone", "rc") < 0);
        //test 4
        assertTrue("rc < 'ga' ", testor.compareVersions("rc", "ga") < 0);
        //test 5
        assertTrue("'final' < sp ", testor.compareVersions("final", "sp") < 0);
        //test 6
        assertTrue("xxx > sp  ", testor.compareVersions("sp", "xxx") < 0);
        //test 7
        assertTrue("sp > 'ga'  ", testor.compareVersions("sp", "ga") > 0);
        //test 8
        assertTrue("xx < xxx", testor.compareVersions("xx", "xxx") < 0);
        //test 9
        assertTrue("a < b", testor.compareVersions("a", "b") < 0);
        //test 10
        assertTrue("a < aa", testor.compareVersions("a", "aa") < 0);
        //test 11
        assertTrue("a == a", testor.compareVersions("a", "a") == 0);
        //test 12
        assertTrue("milestone == milestone", testor.compareVersions("milestone", "milestone") == 0);
    }
    private static final class ComparableVersionTestor {
        int compareVersions(String version, String toVersion) {
            ComparableVersion v = new ComparableVersion(version);
            ComparableVersion toV = new ComparableVersion(toVersion);
            return v.compareTo(toV);
        }
    }

    private static final class ComparableVersionNormalizer {
        String toString(String value) {
            String normalized = null;
            ComparableVersion version = new ComparableVersion(value);
            Class<?> c = version.getClass();
            try {
                Field items = c.getDeclaredField("items");
                items.setAccessible(true);
                Object o = items.get(version);
                normalized = o.toString();

            } catch (NoSuchFieldException e) {
                e.printStackTrace();
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            }
            return normalized;
        }
    }
    public static void main(String[] args) {
        ComparableVersion version = new ComparableVersion("1.0");

        Class<?> c = version.getClass();
        try {
            Field items = c.getDeclaredField("items");
            items.setAccessible(true);
            Object o = items.get(version);
            System.out.println(o.toString());

        } catch (NoSuchFieldException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }

    }
}

