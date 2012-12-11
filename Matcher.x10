import x10.util.ArrayList;
import x10.util.Pair;
import x10.util.concurrent.IntLatch;

/**
 * A match(x) should return with a value of y only when there
 * has in fact been a simultaneous invocation of match(y), and
 * it is the case that (x+y)%n == 1. The match(y) invocation
 * is also required to return with x (the "match"). 
 *
 * The code should not deadlock. If there are match(x) and
 * match(y) invocations s.t. (x+y)%n==1 (and there are no other
 * interfering match calls), then both should return. That is,
 * match calls that can pair up, *should* pair up.
 *
 * The code should also handle the case in which there are
 * multiple oustanding match(...)  invocations with the same
 * argument value. A match(x) invocation should pair up with
 * exactly one match(y) invocation. That is, if simultaneously
 * there are two match(x) and three match(y) invocations (where
 * (x+y)%n==1), then one match(y) invocation should not return
 * until and unless there is a match(z) invocation such that
 * (z+y)%n==1. 
 */ 
public class Matcher {

    /* the n we are using to compute matches */
    val n:Int;

    /* our queue of unmatched integers pair with the
     * latch that will hold their future match. */
    val unmatched = new ArrayList[Pair[Int, IntLatch]]();

    /* instantiate an n-matcher */
    def this(n:Int)
    {
        this.n = n;
    }

    /**
     * If a match is found for i, the function returns the
     * match and causes the matching function call to also
     * return with i.
     *
     * If no match is found, the function call blocks until
     * a match is found.
     *
     * A match(x) should return with a value of y only when
     * there has in fact been a separate invocation of
     * match(y), and it is the case that (x+y)%n == 1. The
     * match(y) invocation is also required to return with
     * x (the "match").
     */
    def match(i:Int):Int
    {
        val p:Pair[Int, IntLatch]; 
        
        /* if match exists, return it. else add i to unmatched list */
        atomic {
            try {
                return getMatch(i);
            } catch (e:RuntimeException) {
                p = new Pair[Int, IntLatch](i, new IntLatch());
                unmatched.add(p);
            }
        }

        /* didn't find a match. wait for a match to occur */
        p.second.await();
        return p.second();
    }

    /**
     * MUST BE CALLED ATOMICALLY OR WILL CAUSE RACE CONDITIONS
     * 
     * checks if an unmatched int exists that will pair with i
     * if so, the unmatched int is returned and i is put into
     * its latch so that it's function call will return as well.
     *
     * if no match is found, throw exception.
     */
    def getMatch(i:Int)
    {
        /* iterate over unmatched items */
        for (j in unmatched) {
            /* if match, trigger latch and return */
            if (isMatch(i, j.first)) {
                unmatched.remove(j);
                j.second.set(i);
                return j.first;
            }
        }

        /* no match; throw exception */
        throw new RuntimeException();
    }

    /* tests our match condition using n */
    private def isMatch(x:Int, y:Int)
    {
        return (x + y) % n == 1;
    }


    /* simple test of the matcher. will hang at the end
     * upon failure, indicating that the matches did not
     * pair up correctly. */
    public static def main(argv:Array[String]{self.rank==1})
    {
        val m = new Matcher(5);
        for (i in 1..1000) async {
            val j = m.match(i);
            Console.OUT.println("MATCH " + i + "  " + j);
        }

    }
}
