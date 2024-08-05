pub mod qq;
use csv::Writer;
use rayon::prelude::*;
use std::iter::repeat_with;
use std::time::Instant;

fn run_experiment(n: usize) -> (usize, f64, f64) {
    let mut rng = fastrand::Rng::new();
    let mut x: Vec<f64> = repeat_with(|| rng.f64()).take(n).collect();
    let mut p: Vec<f64> = x.clone();
    let psum: f64 = p.iter().sum();
    p.iter_mut().for_each(|p_i| *p_i /= psum);
    let alpha: f64 = rng.f64();
    let start = Instant::now();
    qq::cvar(&mut x, &mut p, alpha);
    let fast_cvar_time = start.elapsed().as_secs_f64();
    let start = Instant::now();
    qq::slow_cvar(&x, &p, alpha);
    let slow_cvar_time = start.elapsed().as_secs_f64();
    (n, fast_cvar_time, slow_cvar_time)
}

fn run_batch(n: usize, batch_size: usize) -> Vec<(usize, f64, f64)> {
    (0..batch_size).map(|_| run_experiment(n)).collect()
}

fn main() -> Result<(), csv::Error> {
    let mut writer = Writer::from_path("experiments.csv").unwrap();
    let step_size = 100000;
    let start = 5;
    let end = 10000000;
    let total = (end - start) / step_size;
    let batch_size = 10; // Number of experiments to run for each n
                         // Header row
    writer.write_record(["Size", "Fast_CVaR", "Slow_CVaR"])?;
    // Generate a csv file with experiments
    let n_s = start..end;
    n_s.into_par_iter()
        .step_by(step_size)
        .map(|n| {
            println!("Running experiment {} / {}", n / step_size, total);
            run_batch(n, batch_size)
        })
        .flatten()
        .collect::<Vec<(usize, f64, f64)>>()
        .iter()
        .for_each(|(n, fast_cvar_time, slow_cvar_time)| {
            println!("Writing experiment {} / {}", n / step_size, total);
            writer
                .write_record(&[
                    n.to_string(),
                    fast_cvar_time.to_string(),
                    slow_cvar_time.to_string(),
                ])
                .unwrap();
        });

    writer.flush()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*; // Import functionality from the parent module
    use approx::*;

    #[test]
    fn qql_test() {
        let mut x1 = vec![2.0, 1.0, 3.0];
        let mut p1 = vec![1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0];
        assert_eq!(qq::qql(&mut x1, &mut p1, 0.0), 1.0);
        assert_eq!(qq::qql(&mut x1, &mut p1, 1.0), f64::MAX);
        assert_eq!(qq::qql(&mut x1, &mut p1, 0.5), 2.0);

        let mut x2 = vec![10.0, 2.0, 4.0, 7.0, 8.0];
        let mut p2 = vec![0.1, 0.1, 0.3, 0.3, 0.2];
        assert_eq!(qq::qql(&mut x2, &mut p2, 0.5), 7.0);

        let mut x3 = vec![4.0, 5.0, 1.0, 2.0, -1.0, -2.0];
        let mut p3 = vec![0.1, 0.2, 0.3, 0.1, 0.3, 0.0];
        assert_eq!(qq::qql(&mut x3, &mut p3, 0.0), -1.0);
        assert_eq!(qq::qql(&mut x3, &mut p3, 1.0), f64::MAX);
        assert_eq!(qq::qql(&mut x3, &mut p3, 0.99), 5.0);
        assert_eq!(qq::qql(&mut x3, &mut p3, 0.5), 1.0);
        assert_eq!(qq::qql(&mut x3, &mut p3, 0.4), 1.0);
        assert_eq!(qq::qql(&mut x3, &mut p3, 0.6), 2.0);

        let mut x4 = vec![4.0, 5.0, 1.0, 2.0, -1.0];
        let mut p4 = vec![0.1, 0.2, 0.3, 0.1, 0.3];
        assert_eq!(qq::qql(&mut x4, &mut p4, 1.0), f64::MAX);
        assert_eq!(qq::qql(&mut x4, &mut p4, 0.99), 5.0);
        assert_eq!(qq::qql(&mut x4, &mut p4, 0.0), -1.0);
        assert_eq!(qq::qql(&mut x4, &mut p4, 0.5), 1.0);
        assert_eq!(qq::qql(&mut x4, &mut p4, 0.4), 1.0);

        let mut x5 = vec![2.0, 1.0];
        let mut p5 = vec![0.5, 0.5];
        assert_eq!(qq::qql(&mut x5, &mut p5, 0.5), 2.0);
        assert_eq!(qq::qql(&mut x5, &mut p5, 0.1), 1.0);
        assert_eq!(qq::qql(&mut x5, &mut p5, 0.9), 2.0);
    }

    #[test]
    fn cvar_test() {
        let x1 = [4.0, 5.0, 1.0, 2.0, -1.0, -2.0];
        let p1: [f64; 6] = [0.1, 0.2, 0.3, 0.1, 0.3, 0.0];
        assert_abs_diff_eq!(
            qq::cvar(&mut x1.to_vec(), &mut p1.to_vec(), 0.0),
            -1.0,
            epsilon = f64::EPSILON
        );
        assert_abs_diff_eq!(
            qq::cvar(&mut x1.to_vec(), &mut p1.to_vec(), 0.01),
            -1.0,
            epsilon = f64::EPSILON
        );
        assert_abs_diff_eq!(
            qq::cvar(&mut x1.to_vec(), &mut p1.to_vec(), 1.0),
            1.6,
            epsilon = f64::EPSILON
        );
        assert_abs_diff_eq!(
            qq::cvar(&mut x1.to_vec(), &mut p1.to_vec(), 0.5),
            -0.2,
            epsilon = f64::EPSILON
        );
        assert_abs_diff_eq!(
            qq::cvar(&mut x1.to_vec(), &mut p1.to_vec(), 0.6),
            0.0,
            epsilon = f64::EPSILON
        );

        let x2 = [4.0, 5.0, 1.0, 2.0, -1.0];
        let p2: [f64; 5] = [0.1, 0.2, 0.3, 0.1, 0.3];
        assert_abs_diff_eq!(
            qq::cvar(&mut x2.to_vec(), &mut p2.to_vec(), 0.0),
            -1.0,
            epsilon = f64::EPSILON
        );
        assert_abs_diff_eq!(
            qq::cvar(&mut x2.to_vec(), &mut p2.to_vec(), 1.0),
            1.6,
            epsilon = f64::EPSILON
        );
        assert_abs_diff_eq!(
            qq::cvar(&mut x2.to_vec(), &mut p2.to_vec(), 0.5),
            -0.2,
            epsilon = f64::EPSILON
        );
        assert_abs_diff_eq!(
            qq::cvar(&mut x2.to_vec(), &mut p2.to_vec(), 0.6),
            0.0,
            epsilon = f64::EPSILON
        );
    }

    #[test]
    fn slow_cvar_test() {
        let x1 = vec![4.0, 5.0, 1.0, 2.0, -1.0, -2.0];
        let p1 = vec![0.1, 0.2, 0.3, 0.1, 0.3, 0.0];
        assert_abs_diff_eq!(qq::slow_cvar(&x1, &p1, 0.0), -1.0, epsilon = f64::EPSILON);
        assert_abs_diff_eq!(qq::slow_cvar(&x1, &p1, 0.01), -1.0, epsilon = f64::EPSILON);
        assert_abs_diff_eq!(qq::slow_cvar(&x1, &p1, 1.0), 1.6, epsilon = f64::EPSILON);
        assert_abs_diff_eq!(qq::slow_cvar(&x1, &p1, 0.5), -0.2, epsilon = f64::EPSILON);
        assert_abs_diff_eq!(qq::slow_cvar(&x1, &p1, 0.6), 0.0, epsilon = f64::EPSILON);

        let x2 = vec![4.0, 5.0, 1.0, 2.0, -1.0];
        let p2 = vec![0.1, 0.2, 0.3, 0.1, 0.3];
        assert_abs_diff_eq!(qq::slow_cvar(&x2, &p2, 0.0), -1.0, epsilon = f64::EPSILON);
        assert_abs_diff_eq!(qq::slow_cvar(&x2, &p2, 1.0), 1.6, epsilon = f64::EPSILON);
        assert_abs_diff_eq!(qq::slow_cvar(&x2, &p2, 0.5), -0.2, epsilon = f64::EPSILON);
        assert_abs_diff_eq!(qq::slow_cvar(&x2, &p2, 0.6), 0.0, epsilon = f64::EPSILON);
    }
}
